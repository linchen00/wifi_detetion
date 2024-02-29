package com.any.wifi_detection.network

import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress

class NetBIOSResolver(timeout: Int) : Resolver {

    private val NETBIOS_UDP_PORT = 137
    private val REQUEST_DATA = byteArrayOf(
        0xA2.toByte(),
        0x48,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x20,
        0x43,
        0x4b,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x41,
        0x00,
        0x00,
        0x21,
        0x00,
        0x01
    )

    private val RESPONSE_TYPE_POS = 47
    private val RESPONSE_TYPE_NBSTAT: Byte = 33
    private val RESPONSE_BASE_LEN = 57
    private val RESPONSE_NAME_LEN = 15
    private val RESPONSE_NAME_BLOCK_LEN = 18

    private val GROUP_NAME_FLAG = 128
    private val NAME_TYPE_DOMAIN = 0x00
    private val NAME_TYPE_MESSENGER = 0x03

    private var socket = DatagramSocket()

    init {
        socket.soTimeout = timeout
    }

    override fun resolve(ip: InetAddress): Array<String?>? {
        socket.send(
            DatagramPacket(
                REQUEST_DATA,
                REQUEST_DATA.size,
                ip,
                NETBIOS_UDP_PORT
            )
        )

        val response = ByteArray(1024)
        val responsePacket = DatagramPacket(response, response.size)
        socket.receive(responsePacket)

        if (responsePacket.length < RESPONSE_BASE_LEN || response[RESPONSE_TYPE_POS] != RESPONSE_TYPE_NBSTAT) {
            return null // response was too short - no names returned
        }

        val nameCount = response[RESPONSE_BASE_LEN - 1].toInt() and 0xFF
        if (responsePacket.length < RESPONSE_BASE_LEN + RESPONSE_NAME_BLOCK_LEN * nameCount) {
            return null // data was truncated or something is wrong
        }

        return extractNames(response, nameCount)
    }

    private fun extractNames(response: ByteArray, nameCount: Int): Array<String?> {
        val computerName = if (nameCount > 0) name(response, 0) else null
        var groupName: String? = null
        for (i in 1 until nameCount) {
            if (nameType(response, i) == NAME_TYPE_DOMAIN && (nameFlag(
                    response,
                    i
                ) and GROUP_NAME_FLAG) > 0
            ) {
                groupName = name(response, i)
                break
            }
        }
        var userName: String? = null
        for (i in nameCount - 1 downTo 1) {
            if (nameType(response, i) == NAME_TYPE_MESSENGER) {
                userName = name(response, i)
                break
            }
        }
        val macAddress = String.format(
            "%02X-%02X-%02X-%02X-%02X-%02X",
            nameByte(response, nameCount, 0), nameByte(response, nameCount, 1),
            nameByte(response, nameCount, 2), nameByte(response, nameCount, 3),
            nameByte(response, nameCount, 4), nameByte(response, nameCount, 5)
        )
        return arrayOf(computerName, userName, groupName, macAddress)
    }

    private fun name(response: ByteArray, i: Int): String? {
        // as we have no idea in which encoding are the received names,
        // assume that local default encoding matches the remote one (they are on the same LAN most probably)
        return String(
            response,
            RESPONSE_BASE_LEN + RESPONSE_NAME_BLOCK_LEN * i,
            RESPONSE_NAME_LEN
        ).trim { it <= ' ' }
    }

    private fun nameByte(response: ByteArray, i: Int, n: Int): Int {
        return response[RESPONSE_BASE_LEN + RESPONSE_NAME_BLOCK_LEN * i + n].toInt() and 0xFF
    }

    private fun nameFlag(response: ByteArray, i: Int): Int {
        return response[RESPONSE_BASE_LEN + RESPONSE_NAME_BLOCK_LEN * i + RESPONSE_NAME_LEN + 1].toInt() and 0xFF + (response[RESPONSE_BASE_LEN + RESPONSE_NAME_BLOCK_LEN * i + RESPONSE_NAME_LEN + 2].toInt() and 0xFF) * 0xFF
    }

    private fun nameType(response: ByteArray, i: Int): Int {
        return response[RESPONSE_BASE_LEN + RESPONSE_NAME_BLOCK_LEN * i + RESPONSE_NAME_LEN].toInt() and 0xFF
    }

    override fun close() {
        socket.close()
    }
}