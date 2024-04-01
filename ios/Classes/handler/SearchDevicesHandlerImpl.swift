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
    
   let wireless =  Wireless()
    // Handle events on the main thread.
    var timer = Timer()
    // Declare our eventSink, it will be initialized later
//    private var eventSink: FlutterEventSink?
    
    func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        
        guard wireless.isWiFiConnected()else{
            return FlutterError(code: "2", message: "Wireless is not connected", details: nil)
        }
        let ssid = wireless.getSSID()
        let bssid = wireless.getBSSID()
        let cidr = wireless.getInternalWifiCIDR()
        
        
        print("ssid:\(ssid),bssid:\(bssid),cidr:\(cidr),ip:\(wireless.getInternalWifiIpString())")
        
        let scanHostsAsyncTask = ScanHostsAsyncTask(eventSink: eventSink)
        if let ipv4 = wireless.getInternalWifiIpAddress(),
           let cidr = wireless.getInternalWifiCIDR(){
            print("ipv4: \(ipv4), cidr: \(cidr)")
            scanHostsAsyncTask.scanHosts(ipv4: ipv4, cidr: cidr, timeout: 5000)
        }
        
        
        
        print("onListen......")

        
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            let dateFormat = DateFormatter()
            dateFormat.dateFormat = "HH:mm:ss"
            let time = dateFormat.string(from: Date())
            eventSink(time)
            eventSink(FlutterEndOfEventStream)
        })
    
        
        
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        
        return nil
    }
}


