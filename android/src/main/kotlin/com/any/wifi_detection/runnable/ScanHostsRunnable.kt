package com.any.wifi_detection.runnable

import com.any.wifi_detection.async.ScanHostsAsyncTask
import java.io.Closeable
import java.io.IOException
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket

class ScanHostsRunnable(
        private val start: Int,
        private val stop: Int,
        private val timeout: Int,
) : Runnable,Closeable {

    private val tag = ScanHostsAsyncTask::class.java.simpleName

    private val socket = Socket()

    init {
        socket.tcpNoDelay = true
    }

    override fun run() {
        for (i in start..stop) {
            try {
                val ipAddress = InetAddress.getByName(getIpAddress(i))
                socket.connect(InetSocketAddress(ipAddress, 7), timeout)
                // 连接成功，可以进行相应的操作
            } catch (ignored: IOException) {
                // 连接失败，记录日志或者采取其他措施
            }
        }


    }

    private fun getIpAddress(index: Int): String {
        val byte1 = (index shr 24) and 0xFF
        val byte2 = (index shr 16) and 0xFF
        val byte3 = (index shr 8) and 0xFF
        val byte4 = index and 0xFF
        return "$byte1.$byte2.$byte3.$byte4"
    }

    override fun close() {
        socket.close()
    }
}
