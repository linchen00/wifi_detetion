//
//  ScanHostsRunnable.swift
//  wifi_detection
//
//  Created by arthur on 2024/3/12.
//

import Foundation
import Network
import PlainPing
import PromiseKit


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
        var promises:[Promise<String?>] = []
        
        for i in start...stop {
            let ipAddress = self.getIPAddress(index: i)
            let pingHelper =  PingHelper(ip: ipAddress)
            promises.append(pingHelper.start())
        
        }
        
        when(fulfilled: promises).done { results in
            let filteredArray:[String] = results.compactMap { $0 }
            print("所有的Promise任务执行完毕，结果列表为：", filteredArray)
        }.catch { error in
            print("发生错误：", error)
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
