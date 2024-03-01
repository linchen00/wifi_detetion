package com.any.wifi_detection.handler

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.any.wifi_detection.async.ScanHostsAsyncTask
import com.any.wifi_detection.network.Wireless
import io.flutter.plugin.common.EventChannel
import java.util.Timer
import java.util.TimerTask


class SearchDevicesHandlerImpl(context: Context) : EventChannel.StreamHandler {

    private val tag = SearchDevicesHandlerImpl::class.java.simpleName


    private val wireless = Wireless(context)

    private val mainHandler = Handler(Looper.getMainLooper())
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (!wireless.isEnabled()) {
            events?.error("1", "Wireless is not enabled", null)
            events?.endOfStream()
            return
        }

        if (!wireless.isConnectedWifi()) {
            events?.error("2", "Wireless is not connected", null)
            events?.endOfStream()
            return
        }


        val localIp = wireless.getInternalWifiIpAddress() // 获取内网IP

        val wifiSubnet = wireless.getInternalWifiSubnet() // CIDR 前缀长度


        val timeout = 5000  // 超时时间（毫秒）
        ScanHostsAsyncTask(events)
            .scanHosts(localIp, wifiSubnet, timeout, mainHandler)


        // 模拟发送Stream数据
        val timer = Timer()
        timer.schedule(object : TimerTask() {
            private var counter = 0
            override fun run() {
                mainHandler.post {
                    events?.success(counter++) // 发送事件到Flutter端
                    if (counter == 10) {
                        timer.cancel()
                        events?.endOfStream() // 结束Stream
                    }
                }
            }
        }, 0, 1000)
    }

    override fun onCancel(arguments: Any?) {
    }
}