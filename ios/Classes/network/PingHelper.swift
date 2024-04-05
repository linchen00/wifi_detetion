//
//  PingHelper.swift
//  wifi_detection
//
//  Created by arthur on 2024/4/1.
//

import Foundation
import MacFinder

class PingHelper {
    let ip:String;
    let timeout:TimeInterval;

    private var isOk:Bool = false

    init(ip: String, timeout: TimeInterval = TimeInterval(3)) {
        self.ip = ip
        self.timeout = timeout
    }
    
    func  start () async throws -> String? {
        
        var isSuccess:Bool? = try? await withUnsafeThrowingContinuation({ cont in
            
            if let pinger = try? SwiftyPing(ipv4Address: self.ip, config: PingConfiguration(interval: 0.5, with: timeout), queue: DispatchQueue.global()){
                pinger.finished = { (pingResult) in
                    let responses = pinger.responses
                    let isSuccess = responses.contains { PingResponse in
                        return  PingResponse.error==nil
                    }
                    cont.resume(returning: isSuccess)
                }
                pinger.targetCount = 1
                do {
                    try pinger.startPinging()
                } catch {
                    cont.resume(returning: false)
                }
            }else{
                cont.resume(returning: false)
            }
            
        })
        if (isSuccess != true) && (MacFinder.ip2mac(self.ip) != nil){
            isSuccess = true
        }
        if (isSuccess == true) {
            return self.ip
        }else{
            return nil
        }
    }
}
