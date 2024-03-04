//
//  SearchDevicesHandlerImpl.swift
//  wifi_detection
//
//  Created by arthur on 2024/3/4.
//

import Foundation
import Flutter
import Network


class SearchDevicesHandlerImpl: NSObject, FlutterStreamHandler {
    // Handle events on the main thread.
    var timer = Timer()
    // Declare our eventSink, it will be initialized later
    private var eventSink: FlutterEventSink?
    
    func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        print("onListen......")
        self.eventSink = eventSink
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            let dateFormat = DateFormatter()
            dateFormat.dateFormat = "HH:mm:ss"
            let time = dateFormat.string(from: Date())
            eventSink(time)
            eventSink(FlutterEndOfEventStream)
        })
        
        let monitor = NWPathMonitor()
        monitor.currentPath.usesInterfaceType(.wifi)
        
        
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}


