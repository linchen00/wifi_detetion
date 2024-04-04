//
//  ScanHostsAsyncTask.swift
//  wifi_detection
//
//  Created by arthur on 2024/4/3.
//

import Foundation
import Flutter

class ScanHostsAsyncTask{
    
    let eventSink:FlutterEventSink
    
    init(eventSink:@escaping  FlutterEventSink) {
        self.eventSink = eventSink
    }
    
    func scanHosts(ipv4:Int,cidr:Int,timeout:Int) async{
    
        let hostBits = 32.0 - Double(cidr)
        let netmask = (0xFFFFFFFF >> (32 - cidr)) << (32 - cidr)
        let numberOfHosts = pow(2.0, hostBits) - 2
        let firstAddr = (ipv4 & netmask) + 1
        
        let scanThreads = hostBits
        let chunk = Int(ceil(numberOfHosts / scanThreads))
        var previousStart = firstAddr
        var previousStop = firstAddr + (chunk - 2)
        
        
     let ipList =  await withTaskGroup(of: [String].self, returning: [String].self) { taskGroup in
           for _ in 1..<Int(scanThreads){
               let start =  previousStart
               let stop =  previousStop
               taskGroup.addTask {
                   let scanHostsRunnable = ScanHostsRunnable(start: start, stop: stop, timeout: TimeInterval(5*60))
                   let results = await scanHostsRunnable.run()
                   return results
               }
               
               previousStart = stop+1
               previousStop = previousStart+(chunk-1)
           }
           
           var ipList:[String] = []
           
           for await taskResult in taskGroup {
               ipList.append(contentsOf: taskResult)
           }
           
           return ipList
        }
        
        print("ipList:\(ipList)")

    }

}
