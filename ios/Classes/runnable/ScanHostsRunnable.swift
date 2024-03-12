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

        for i in start...stop {
            // 将任务添加到串行队列中，确保按顺序执行
            serialQueue.async {
                let ipAddress = self.getIPAddress(index: i)
                let pinger = try? SwiftyPing(host: ipAddress, configuration: PingConfiguration(interval:0,with: 10), queue: self.serialQueue)
                
                // 将当前任务添加到 DispatchGroup 中
//                
//                
                pinger?.observer = { (response:PingResponse) in
                    print("ipAddress:\(ipAddress),duration:\(response.duration),error:\(response.error)")
                    
                    // 任务完成后离开 DispatchGroup
//                    self.group.leave()
                }
                
                pinger?.targetCount = 1
//                self.group.enter()
                try? pinger?.startPinging()
                
//                self.group.enter()
//                let ipAddress = self.getIPAddress(index: i)
//                print("ipAddress:\(ipAddress)")
//                if ipAddress != "192.168.1.5"{
//                    self.group.leave()
//                }
                

            }
        }

        // 等待所有任务完成
        self.group.wait()
        print("asd")
        
        

        
    }
    
    
    func getIPAddress(index: Int) -> String {
        let byte1 = UInt8((index >> 24) & 0xFF)
        let byte2 = UInt8((index >> 16) & 0xFF)
        let byte3 = UInt8((index >> 8) & 0xFF)
        let byte4 = UInt8(index & 0xFF)
        return "\(byte1).\(byte2).\(byte3).\(byte4)"
    }
    
}
