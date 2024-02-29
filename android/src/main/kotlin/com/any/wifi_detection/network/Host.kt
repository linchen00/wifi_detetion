package com.any.wifi_detection.network

import java.net.InetAddress

data class Host(val ip: String, val mac: String) {

    public var address: ByteArray = InetAddress.getByName(ip).address


    public var hostname: String? = null
        set(value) {
            field = if (value != null && (value.isEmpty() || value.endsWith(".local"))) {
                value.substring(0, value.length - 6)
            } else {
                value
            }

        }

    public val vendor: String? = null


    override fun toString(): String {
        return "Host(ip='$ip', mac='$mac', address=${address.contentToString()}, hostname=$hostname, vendor=$vendor)"
    }


}