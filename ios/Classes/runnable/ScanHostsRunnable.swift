//
//  ScanHostsRunnable.swift
//  wifi_detection
//
//  Created by arthur on 2024/3/12.
//

import Foundation
import Network
import PlainPing


class ScanHostsRunnable{
    let start :Int
    let stop :Int
    let timeout :Int
    
    // 创建一个 DispatchGroup 对象
    let group = DispatchGroup()

    // 创建一个串行队列
    let serialQueue = DispatchQueue(label: "com.example.ping.serialQueue")
    
    
    init(start: Int, stop: Int, timeout: Int) {
        self.start = start
        self.stop = stop
        self.timeout = timeout
    }
    
    func run() {
        
        var ipList = [String]()
        
        for i in start...stop {
            let ipAddress = self.getIPAddress(index: i)
            print("ipAddress:\(ipAddress)");
        }
    }
    
    
    func getIPAddress(index: Int) -> String {
        let byte1 = UInt8((index >> 24) & 0xFF)
        let byte2 = UInt8((index >> 16) & 0xFF)
        let byte3 = UInt8((index >> 8) & 0xFF)
        let byte4 = UInt8(index & 0xFF)
        return "\(byte1).\(byte2).\(byte3).\(byte4)"
    }
    
}
