package com.any.wifi_detection.handler

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import java.util.Timer
import java.util.TimerTask


class SearchDevicesHandlerImpl: EventChannel.StreamHandler {

    private val mainHandler = Handler(Looper.getMainLooper())
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {

        // 模拟发送Stream数据
        val timer = Timer()
        timer.schedule(object : TimerTask() {
            private var counter = 0
            override fun run() {
                mainHandler.post {
                    events!!.success(counter++) // 发送事件到Flutter端
                    if (counter == 10) {
                        timer.cancel()
                        events.endOfStream() // 结束Stream
                    }
                }
            }
        }, 0, 1000)
    }

    override fun onCancel(arguments: Any?) {
    }
}