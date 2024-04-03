//
//  PingHelper.swift
//  wifi_detection
//
//  Created by arthur on 2024/4/1.
//

import Foundation
import PlainPing
import MacFinder
import PromiseKit

class PingHelper {
    let ip:String;
    let timeout:Int;

    var isOk:Bool = false

    init(ip: String, timeout: Int = 3) {
        self.ip = ip
        self.timeout = timeout
    }

    
    func start()->Promise<String?>{
        // 在主线程中执行异步任务
        return  Promise<String?>{seal in
            
            if let pinger = try? SwiftyPing(ipv4Address: self.ip, config: PingConfiguration(interval: 0.5, with: TimeInterval(timeout)), queue: DispatchQueue.global()){
                pinger.finished = { (pingResult) in
                    let responses = pinger.responses
                    self.isOk = responses.contains { PingResponse in
                        return  PingResponse.error==nil
                    }
                    
                    if !self.isOk && (MacFinder.ip2mac(self.ip) != nil){
                        self.isOk = true
                    }
                    if self.isOk {
                        seal.fulfill(self.ip)
                    }else{
                        seal.fulfill(nil)
                    }
                    
                }
                pinger.targetCount = 1
                do {
                    try pinger.startPinging()
                } catch {
                    seal.fulfill(nil)
                }
            }else{
                if (MacFinder.ip2mac(ip) != nil)  {
                    self.isOk = true
                }
                if self.isOk {
                    seal.fulfill(self.ip)
                }else{
                    seal.fulfill(nil)
                }
            }
            
        } 
    }
}
