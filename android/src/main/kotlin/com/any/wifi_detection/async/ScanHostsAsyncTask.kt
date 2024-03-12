package com.any.wifi_detection.async

import android.os.Handler
import android.os.ParcelFileDescriptor
import android.text.format.DateUtils
import android.util.Pair
import com.any.wifi_detection.network.Host
import com.any.wifi_detection.network.MDNSResolver
import com.any.wifi_detection.network.NetBIOSResolver
import com.any.wifi_detection.network.Resolver
import com.any.wifi_detection.runnable.ScanHostsRunnable
import com.google.gson.Gson
import io.flutter.plugin.common.EventChannel.EventSink
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.cancelChildren
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.net.InetAddress
import java.net.UnknownHostException
import java.nio.charset.StandardCharsets
import kotlin.math.ceil
import kotlin.math.pow


class ScanHostsAsyncTask(private val eventSink: EventSink?, private val mainHandler: Handler) {

    init {
        System.loadLibrary("ipneigh")
    }

    private external fun nativeIPNeigh(fd: Int): Int

    private val tag = ScanHostsAsyncTask::class.java.simpleName

    private val neighborIncomplete = "INCOMPLETE"
    private val neighborFailed = "FAILED"

    fun scanHosts(ipv4: Int, cidr: Int, timeout: Int) {

        // 创建一个固定大小的线程池，其中包含多个线程
        val hostBits = 32.0 - cidr
        val netmask = -0x1 shr 32 - cidr shl 32 - cidr
        val numberOfHosts = 2.0.pow(hostBits).toInt() - 2
        val firstAddr = (ipv4 and netmask) + 1

        val scanThreads = hostBits.toInt()
        val chunk = ceil(numberOfHosts.toDouble() / scanThreads).toInt()
        var previousStart = firstAddr
        var previousStop = firstAddr + (chunk - 2)

        // 提交任务给线程池执行
        runBlocking {
            val scanHostJob = async {
                withTimeout(5 * DateUtils.MINUTE_IN_MILLIS) {
                    withContext(Dispatchers.IO) {
                        coroutineScope {
                            for (i in 0 until scanThreads) {
                                launch {
                                    val scanHostsRunnable = ScanHostsRunnable(previousStart + chunk * i, previousStop + chunk * i, timeout)
                                    scanHostsRunnable.run()
                                    scanHostsRunnable.close()
                                }
                                previousStart = previousStop + 1
                                previousStop = previousStart + (chunk - 1)
                            }
                        }
                    }
                }
            }

            try {

                scanHostJob.await()
                println("All scan tasks completed")
            } catch (e: TimeoutCancellationException) {
                e.printStackTrace()
                println("Total timeout exceeded, canceling all scan tasks")
                scanHostJob.cancelChildren() // 超时时取消所有协程
            }

            val arpList = parseAndExtractValidArpFromInputStream()
            println("arpList:$arpList")
            processPairs(arpList, eventSink)
        }
    }

    private fun parseAndExtractValidArpFromInputStream(): MutableList<Pair<String, String>> {

        val pairs: MutableList<Pair<String, String>> = ArrayList()


        val pipe: Array<ParcelFileDescriptor> = ParcelFileDescriptor.createPipe()
        val readSidePfd = pipe[0]
        val writeSidePfd = pipe[1]
        val inputStream = ParcelFileDescriptor.AutoCloseInputStream(readSidePfd)

        val fdWrite = writeSidePfd.detachFd()
        val returnCode: Int = nativeIPNeigh(fdWrite)

        if (returnCode != 0) {
            return pairs
        }

        val reader = BufferedReader(InputStreamReader(inputStream, StandardCharsets.UTF_8))
        reader.useLines { lines ->
            lines.forEach { line ->
                val neighborLine = line.split(Regex("\\s+"))
                if (neighborLine.size > 5) {
                    val ip = neighborLine[0]
                    val macAddress = neighborLine[4]
                    val state = neighborLine.last()

                    try {
                        val address = InetAddress.getByName(ip)
                        // 排除Link-local和Loopback地址
                        if (!address.isLinkLocalAddress && !address.isLoopbackAddress) {
                            // 有效ARP条目的状态不是Failed或者Incomplete
                            // Determine if the ARP entry is valid.
                            // https://github.com/sivasankariit/iproute2/blob/master/ip/ipneigh.c
                            if (state != neighborFailed && state != neighborIncomplete) {
                                pairs.add(Pair<String, String>(ip, macAddress))
                            }
                        }
                    } catch (e: UnknownHostException) {
                        // 处理IP地址解析异常
                        e.printStackTrace()
                    }
                }
            }
        }

        return pairs

    }

    private suspend fun processPairs(pairs: List<Pair<String, String>>, eventSink: EventSink?) {
        withContext(Dispatchers.IO) {
            coroutineScope {
                pairs.forEach { pair ->
                    val ip = pair.first
                    val macAddress = pair.second

                    launch {
                        val host = Host(ip, macAddress)
                        try {
                            val add = try {
                                InetAddress.getByName(ip)
                            } catch (e: UnknownHostException) {
                                return@launch
                            }

                            val hostname = add.canonicalHostName
                            println("hostname:$hostname")
                            host.hostname = hostname

                            // BUG: Some devices don't respond to mDNS if NetBIOS is queried first. Why?
                            // So let's query mDNS first, to keep in mind for eventual UPnP implementation.
                            val lanSocketTimeout = 5000
                            val isResolveHostName = resolveHostName(ip, host, MDNSResolver(lanSocketTimeout))
                            if (!isResolveHostName) {
                                resolveHostName(ip, host, NetBIOSResolver(lanSocketTimeout))
                            }
                            mainHandler.post {
                                eventSink?.success(Gson().toJson(host))
                            }
                        } catch (e: Exception) {
                            e.printStackTrace()
                            mainHandler.post {
                                eventSink?.success(Gson().toJson(host))
                            }
                        }
                    }
                }
            }
        }
    }

    private fun resolveHostName(
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