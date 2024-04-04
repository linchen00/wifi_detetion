//
//  ScanHostsRunnable.swift
//  wifi_detection
//
//  Created by arthur on 2024/3/12.
//

import Foundation
import Network


class ScanHostsRunnable{
    let start :Int
    let stop :Int
    let timeout :TimeInterval
    
    init(start: Int, stop: Int, timeout: TimeInterval) {
        self.start = start
        self.stop = stop
        self.timeout = timeout
    }
    
    func run()async -> [String] {
        var ipList:[String] = []
        
        for i in start...stop {
            let ipAddress = self.getIPAddress(index: i)
            let pingHelper =  PingHelper(ip: ipAddress,timeout: TimeInterval(1))
            if let test = try? await pingHelper.start() {
                ipList.append(test)
            }
        }
        return ipList
    }
    
    
    func getIPAddress(index: Int) -> String {
        let byte1 = UInt8((index >> 24) & 0xFF)
        let byte2 = UInt8((index >> 16) & 0xFF)
        let byte3 = UInt8((index >> 8) & 0xFF)
        let byte4 = UInt8(index & 0xFF)
        return "\(byte1).\(byte2).\(byte3).\(byte4)"
    }
    
}
