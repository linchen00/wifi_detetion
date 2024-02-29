package com.any.wifi_detection.runnable

import android.os.Handler
import io.flutter.plugin.common.EventChannel.EventSink
import java.io.IOException
import java.math.BigInteger
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket

class ScanHostsRunnable(
    private val start: Int,
    private val stop: Int,
    private val timeout: Int,
) : Runnable {

    override fun run() {
        for (i in start..stop) {
            try {
                Socket().use { socket ->
                    socket.tcpNoDelay = true
                    val bytes = BigInteger.valueOf(i.toLong()).toByteArray()
                    socket.connect(
                        InetSocketAddress(InetAddress.getByAddress(bytes), 7),
                        timeout
                    )
                }
            } catch (ignored: IOException) {
                // Connection failures aren't errors in this case.
                // We want to fill up the ARP table with our connection attempts.
            }
        }

    }
}