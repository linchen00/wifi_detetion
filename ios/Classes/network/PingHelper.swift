//
//  PingHelper.swift
//  wifi_detection
//
//  Created by arthur on 2024/4/1.
//

import Foundation
import PlainPing
import MacFinder

class PingHelper {
    let ip:String;
    let timeout:Int;

    var isOk:Bool = false

    init(ip: String, timeout: Int = 3) {
        self.ip = ip
        self.timeout = timeout
    }
    
    func start()->Bool{

        print("start:\(self.ip)")
        // 在主线程中执行异步任务
        let queue = DispatchQueue.global()
        let semaphore = DispatchSemaphore(value: 0)
        queue.async {
            PlainPing.ping(self.ip, withTimeout: TimeInterval(self.timeout)) { elapsedTimeMs, error in
                
                self.isOk = error == nil
                if let latency = elapsedTimeMs {
                    print("\(self.ip) latency (ms): \(latency)")
                }
                if let error = error {
                    print("error: \(error.localizedDescription)")
                }
                semaphore.signal()
                
            }
            // 在当前线程启动运行循环
            let runLoop = RunLoop.current
            runLoop.run()
            
        }
        semaphore.wait()
        
        if !self.isOk &&  (MacFinder.ip2mac(ip) != nil)  {
            self.isOk = true
            
        }
    
        
       
        print("finish:\(self.ip)")
        return self.isOk
        
        
        
    }
}
