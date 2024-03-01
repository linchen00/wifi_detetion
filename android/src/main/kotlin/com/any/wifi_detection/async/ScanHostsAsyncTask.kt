package com.any.wifi_detection.async

import android.os.Handler
import android.os.ParcelFileDescriptor
import android.util.Log
import android.util.Pair
import com.any.wifi_detection.network.Host
import com.any.wifi_detection.network.MDNSResolver
import com.any.wifi_detection.network.NetBIOSResolver
import com.any.wifi_detection.network.Resolver
import com.any.wifi_detection.runnable.ScanHostsRunnable
import com.google.gson.Gson
import io.flutter.plugin.common.EventChannel.EventSink
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.net.InetAddress
import java.net.UnknownHostException
import java.nio.charset.StandardCharsets
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

class ScanHostsAsyncTask(private val eventSink: EventSink?) {

    init {
        System.loadLibrary("ipneigh")
    }

    private external fun nativeIPNeigh(fd: Int): Int

    private val tag = ScanHostsAsyncTask::class.java.simpleName

    private val NEIGHBOR_INCOMPLETE = "INCOMPLETE"
    private val NEIGHBOR_FAILED = "FAILED"

    fun scanHosts(ipv4: Int, cidr: Int, timeout: Int, mainHandler: Handler?) {

        // 创建一个固定大小的线程池，其中包含多个线程
        val executor = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors())
        try {
            val hostBits = 32.0 - cidr
            val netmask = -0x1 shr 32 - cidr shl 32 - cidr
            val numberOfHosts = Math.pow(2.0, hostBits).toInt() - 2
            val firstAddr = (ipv4 and netmask) + 1
            val SCAN_THREADS = hostBits.toInt()
            val chunk = Math.ceil(numberOfHosts.toDouble() / SCAN_THREADS).toInt()
            var previousStart = firstAddr
            var previousStop = firstAddr + (chunk - 2)

            // 提交任务给线程池执行
            for (i in 0 until SCAN_THREADS) {
                executor.execute(
                    ScanHostsRunnable(previousStart, previousStop, timeout)
                )
                previousStart = previousStop + 1
                previousStop = previousStart + (chunk - 1)
            }

            // 关闭线程池
            executor.shutdown()
            // 等待线程池中的任务执行完成，最多等待5分钟
            if (!executor.awaitTermination(5, TimeUnit.MINUTES)) {
                // 如果超时，立即中断所有任务
                executor.shutdownNow()
            }
        } catch (e: InterruptedException) {
            // 捕获中断异常
            e.printStackTrace()
        }
        fetchAndProcessArpEntries()
    }

    private fun fetchAndProcessArpEntries() {
        val executor = Executors.newCachedThreadPool()
        val numHosts = AtomicInteger(0)
        val pairs: MutableList<Pair<String, String>> = ArrayList()


        val pipe: Array<ParcelFileDescriptor> = ParcelFileDescriptor.createPipe()
        val readSidePfd = pipe[0]
        val writeSidePfd = pipe[1]
        val inputStream = ParcelFileDescriptor.AutoCloseInputStream(readSidePfd)

        val fdWrite = writeSidePfd.detachFd()
        val returnCode: Int = nativeIPNeigh(fdWrite)

        if (returnCode != 0) {
            executor.shutdown()
            eventSink?.endOfStream()
            return
        }

        val reader = BufferedReader(InputStreamReader(inputStream, StandardCharsets.UTF_8))

        while (true) {
            var line: String
            try {
                line = reader.readLine() ?: break
            } catch (e: IOException) {
                executor.shutdown()
                eventSink?.endOfStream()
                return
            }

            val neighborLine = line.split(Regex("\\s+"))

            // We don't have a validated ARP entry for this case.
            if (neighborLine.size <= 4) {
                continue
            }

            val ip = neighborLine[0]

            val addr: InetAddress = try {
                InetAddress.getByName(ip)
            } catch (e: UnknownHostException) {
                executor.shutdown()
                eventSink?.endOfStream()
                return
            }

            if (addr.isLinkLocalAddress || addr.isLoopbackAddress) {
                continue
            }

            val macAddress = neighborLine[4]
            val state = neighborLine[neighborLine.size - 1]

            // Determine if the ARP entry is valid.
            // https://github.com/sivasankariit/iproute2/blob/master/ip/ipneigh.c
            if (NEIGHBOR_FAILED != state && NEIGHBOR_INCOMPLETE != state) {
                pairs.add(Pair<String, String>(ip, macAddress))
            }
        }
        numHosts.addAndGet(pairs.size)

        for (pair: Pair<String, String> in pairs) {
            val ip = pair.first
            val macAddress = pair.second

            executor.execute {

                val host = try {
                    Host(ip, macAddress)
                } catch (e: UnknownHostException) {
                    executor.shutdown()
                    eventSink?.endOfStream()
                    return@execute
                }

                val add = try {
                    InetAddress.getByName(ip)
                } catch (e: UnknownHostException) {
                    executor.shutdown()
                    eventSink?.endOfStream()
                    return@execute
                }

                val hostname = add.canonicalHostName
                host.hostname = hostname


                // BUG: Some devices don't respond to mDNS if NetBIOS is queried first. Why?
                // So let's query mDNS first, to keep in mind for eventual UPnP implementation.
                val lanSocketTimeout = 5000
                try {

                    val isResolve = resolve(
                        ip,
                        host,
                        MDNSResolver(lanSocketTimeout)
                    )
                    if (isResolve) {
                        Log.d(tag, "fetchAndProcessArpEntries: ${ Gson().toJson(host)}")
                        return@execute
                    }

                    resolve(
                        ip,
                        host,
                        NetBIOSResolver(lanSocketTimeout)
                    )
                } catch (ignored: Exception) {
                }


            }
        }
    }

    private fun resolve(
        ip: String,
        host: Host,
        resolver: Resolver
    ): Boolean {
        val add = try {
            InetAddress.getByName(ip)
        } catch (e: UnknownHostException) {
            resolver.close()
            return false
        }
        val name = try {
            resolver.resolve(add)
        } catch (e: IOException) {
            resolver.close()
            return false
        }
        resolver.close()
        if ((name != null) && !name.first().isNullOrBlank()) {
            host.hostname = name[0]
            return true
        }
        return false
    }


}