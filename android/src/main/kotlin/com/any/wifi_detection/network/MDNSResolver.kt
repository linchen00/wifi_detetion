package com.any.wifi_detection.network

import java.io.ByteArrayOutputStream
import java.io.Closeable
import java.io.DataOutputStream
import java.net.DatagramPacket
import java.net.InetAddress
import java.net.MulticastSocket

class MDNSResolver(timeout: Int) : Closeable, Resolver {
    private val mdnsIP = InetAddress.getByName("224.0.0.251")
    private val mdnsPort = 5353
    private val socket = MulticastSocket()

    init {
        socket.soTimeout = timeout
        socket.timeToLive = 1
        socket.joinGroup(mdnsIP)
    }

    private fun writeName(out: DataOutputStream, name: String) {
        var s = 0
        var e = name.indexOf('.', s)
        while (e != -1) {
            out.writeByte(e - s)
            out.write(name.substring(s, e).toByteArray())
            s = e + 1
            e = name.indexOf('.', s)
        }
        out.write(name.length - s)
        out.write(name.substring(s).toByteArray())
        out.writeByte(0)
    }

    private fun decodeName(data: ByteArray, offset: Int, length: Int): String {
        val s = StringBuilder(length)
        var i = offset
        while (i < offset + length) {
            val len: Byte = data[i]
            if (len == 0.toByte()) break
            s.append(String(data, i + 1, len.toInt())).append('.')
            i += len + 1
        }
        s.setLength(s.length - 1)
        return s.toString()
    }

    private fun dnsRequest(id: Int, name: String): ByteArray {
        val byteArrayOutputStream = ByteArrayOutputStream()
        val dataOutputStream = DataOutputStream(byteArrayOutputStream)
        dataOutputStream.writeShort(id)
        dataOutputStream.write(byteArrayOf(0, 0, 0, 1, 0, 0, 0, 0, 0, 0))
        writeName(dataOutputStream, name)
        dataOutputStream.write(byteArrayOf(0, 0xc, 0, 1))
        return byteArrayOutputStream.toByteArray()
    }

    private fun reverseName(addr: ByteArray): String {
        // note: only IPv4 is supported here
        return (addr[3].toInt() and 0xFF).toString() + "." + (addr[2].toInt() and 0xFF) + "." + (addr[1].toInt() and 0xFF) + "." + (addr[0].toInt() and 0xFF) + ".in-addr.arpa"
    }

    override fun resolve(ip: InetAddress): Array<String?>? {
        val addr = ip.address
        val requestId = addr!![2] * 0xFF + addr[3]
        val request = dnsRequest(requestId, reverseName(addr))
        socket.send(DatagramPacket(request, request.size, mdnsIP, mdnsPort))

        val respPacket = DatagramPacket(ByteArray(512), 512)
        socket.receive(respPacket)
        val response = respPacket.data
        if (response[0] != request[0] && response[1] != request[1]) return null
        val numQueries = response[5].toInt()
        val offset =
            (if (numQueries == 0) 12 + reverseName(addr).length else request.size) + 2 + 2 + 2 + 4 + 2
        return arrayOf(decodeName(response, offset, respPacket.length - offset))
    }

    override fun close() {
        socket.close()
    }
}