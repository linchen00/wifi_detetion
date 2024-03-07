package com.any.wifi_detection.network

import android.annotation.SuppressLint
import android.content.Context
import android.net.ConnectivityManager
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import java.net.InetAddress
import java.net.NetworkInterface
import java.nio.ByteOrder

class Wireless(private val context: Context) {


    /**
     * Gets the MAC address of the device
     *
     * @return MAC address
     */
    fun getMacAddress(): String? {
        @SuppressLint("HardwareIds") val address =
            getWifiInfo().macAddress // Won't work on Android 6+ https://developer.android.com/about/versions/marshmallow/android-6.0-changes.html#behavior-hardware-id

        if ("02:00:00:00:00:00" != address) {
            return address
        }

        // This should get us the device's MAC address on Android 6+
        val networkInterface =
            NetworkInterface.getByInetAddress(getWifiInetAddress()) ?: return null

        val mac: ByteArray = networkInterface.getHardwareAddress() ?: return null

        val buf = StringBuilder()
        for (aMac in mac) {
            buf.append(String.format("%02x:", aMac))
        }

        if (buf.isNotEmpty()) {
            buf.deleteCharAt(buf.length - 1)
        }

        return buf.toString()
    }

    /**
     * Gets the SSID of the wireless network that the device is connected to
     *
     * @return SSID
     */
    fun getSSID(): String {
        var ssid = getWifiInfo().getSSID()
        if (ssid.startsWith("\"") && ssid.endsWith("\"")) {
            ssid = ssid.substring(1, ssid.length - 1)
        }

        return ssid
    }

    /**
     * Gets the BSSID of the wireless network that the device is connected to
     *
     * @return BSSID
     */
    fun getBSSID(): String {
        return getWifiInfo().bssid
    }

    /**
     * Gets the signal strength of the wireless network that the device is connected to
     *
     * @return Signal strength
     */
    fun getSignalStrength(): Int {
        return getWifiInfo().rssi
    }

    /**
     * Determines if WiFi is enabled on the device or not
     *
     * @return True if enabled, false if disabled
     */
    fun isEnabled(): Boolean {
        return getWifiManager().isWifiEnabled
    }

    /**
     * Determines if the device is connected to a WiFi network or not
     *
     * @return True if the device is connected, false if it isn't
     */
    fun isConnectedWifi(): Boolean {
        val info = getConnectivityManager().getNetworkInfo(ConnectivityManager.TYPE_WIFI)
        return info != null && info.isConnectedOrConnecting
    }

    /**
     * Gets the current link speed of the wireless network that the device is connected to
     *
     * @return Wireless link speed
     */
    fun getLinkSpeed(): Int {
        return getWifiInfo().linkSpeed
    }

    /**
     * Gets the device's internal LAN IP address associated with the WiFi network
     *
     * @return Local WiFi network LAN IP address
     */
    fun getInternalWifiIpAddress(): Int {
        var ip = getWifiInfo().getIpAddress()

        if (ByteOrder.nativeOrder() == ByteOrder.LITTLE_ENDIAN) {
            ip = Integer.reverseBytes(ip)
        }
        return ip
    }

    fun getInternalWifiIpString(): String {
        val internalWifiIp = getInternalWifiIpAddress()
        val bytes = ByteArray(4)
        bytes[0] = (internalWifiIp shr 24 and 0xFF).toByte()
        bytes[1] = (internalWifiIp shr 16 and 0xFF).toByte()
        bytes[2] = (internalWifiIp shr 8 and 0xFF).toByte()
        bytes[3] = (internalWifiIp and 0xFF).toByte()
        return "${bytes[0].toInt() and 0xFF}.${bytes[1].toInt() and 0xFF}.${bytes[2].toInt() and 0xFF}.${bytes[3].toInt() and 0xFF}"

    }

    /**
     * Gets the Wifi Manager DHCP information and returns the Netmask of the internal Wifi Network as an int
     *
     * @return Internal Wifi Subnet Netmask
     */
    fun getInternalWifiSubnet(): Int {
        val wifiManager = getWifiManager()
        val dhcpInfo = wifiManager.dhcpInfo ?: return 0
        val netmask = Integer.bitCount(dhcpInfo.netmask)
        /*
        * Workaround for #82477
        * https://code.google.com/p/android/issues/detail?id=82477
        * If dhcpInfo returns a subnet that cannot exist, then
        * look up the Network interface instead.
        */
        if (netmask < 4 || netmask > 32) {
            try {
                val wifiInetAddress = getWifiInetAddress() ?: return 0
                val networkInterface =
                    NetworkInterface.getByInetAddress(wifiInetAddress) ?: return 0
                for (address in networkInterface.getInterfaceAddresses()) {
                    if (wifiInetAddress == address.address) {
                        return address.networkPrefixLength.toInt() // This returns a short of the CIDR notation.
                    }
                }
            } catch (ignored: Exception) {
            }
        }


        return netmask
    }

    /**
     * Gets the device's wireless address
     *
     * @return Wireless address
     */
    private fun getWifiInetAddress(): InetAddress? {
        val ipAddress = getInternalWifiIpString()
        return InetAddress.getByName(ipAddress)
    }

    /**
     * Returns the number of hosts in the subnet.
     *
     * @return Number of hosts as an integer.
     */
    fun getNumberOfHostsInWifiSubnet(): Int {
        val subnet: Double = getInternalWifiSubnet().toDouble()
        val bitsLeft = 32.0 - subnet
        // 减去 2 是因为要排除网络地址和广播地址
        val hosts = Math.pow(2.0, bitsLeft) - 2.0

        return hosts.toInt()
    }

    /**
     * Gets the Android WiFi information in the context of the current activity
     *
     * @return WiFi information
     */
    private fun getWifiInfo(): WifiInfo {
        return getWifiManager().connectionInfo
    }

    /**
     * Gets the Android connectivity manager in the context of the current activity
     *
     * @return Connectivity manager
     */
    private fun getConnectivityManager(): ConnectivityManager {
        return (context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager)
    }

    /**
     * Gets the Android WiFi manager in the context of the current activity
     *
     * @return WifiManager
     */
    private fun getWifiManager(): WifiManager {
        return context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
    }


}