//
//  NetworkTool.swift
//  wifi_detection
//
//  Created by arthur on 2024/3/28.
//

import Foundation
import CocoaAsyncSocket
import Network


class NetworkTool: NSObject, GCDAsyncUdpSocketDelegate {
    
    let udpTimeOut:TimeInterval = TimeInterval(4);
    let mdnsIP:String = "224.0.0.251";

    let mdnsPort:UInt16 = 5353;
    
    let group = DispatchGroup()
    /// UDP
    private lazy var udp: GCDAsyncUdpSocket = {
        return GCDAsyncUdpSocket(delegate: self, delegateQueue: .main)
        
    }()
    
    /// 指定设备发送广播
    func udpBroadcast(ip: String) {
        self.udpDefalut()
        self.boardDeviceInfo(ip: ip)
    }
    
    /// UDP 默认设置
    func udpDefalut() {
        
        do {
            try self.udp.enableReusePort(true)
            try self.udp.bind(toPort: 4605)
            try self.udp.enableBroadcast(true)
            try self.udp.joinMulticastGroup(mdnsIP)
            try self.udp.beginReceiving()
        } catch let error {
            print("udp失败\(error)")
        }
    }
    
    /// deviceInfo
    func boardDeviceInfo(ip: String) {
        if let requestID = calculateRequestID(ip: ip){
            let data = dnsRequest(id: requestID, name: reverseName(name: ip)) //得发送data才能得到回应，这个根据交互方案传值
            self.udp.send(Data(data), toHost: mdnsIP, port: mdnsPort, withTimeout: self.udpTimeOut, tag: 123)
        }else {
            return
        }
    }
    
    func calculateRequestID(ip:String ) -> Int?{
        let addrParts = ip.split(separator: ".").compactMap { Int($0) }
        
        guard addrParts.count == 4 else {
           return nil
        }
        let requestID = addrParts[2] * 255 + addrParts[3]
        return requestID;
    }

    func reverseName(name:String) -> String{
        let addr = name.split(separator: ".")
        return "\(addr[3]).\(addr[2]).\(addr[1]).\(addr[0]).in-addr.arpa";
    }
    
    
    
    
    func dnsRequest(id: Int, name: String) -> [UInt8] {
        var byteArray = [UInt8]()
        
        // ID
        byteArray += [UInt8(id >> 8), UInt8(id & 0xff)]
        
        // Flags
        byteArray += [0, 0, 0, 1, 0, 0, 0, 0, 0, 0]
    
        // Name
        let labels = name.split(separator: ".")
        for label in labels {
            byteArray.append(UInt8(label.count))
            byteArray.append(contentsOf: label.utf8)
        }
        byteArray.append(0) // 最后一个标签以0结尾
        
        // Type (PTR)
        byteArray += [0, 12]
        
        // Class (IN)
        byteArray += [0, 1]
        
        return byteArray
    }
    
    func decodeName( bytes:[UInt8],offset :Int,length :Int) ->String?{
        
        var name:String = ""
        
        var i = offset
        
        while i<offset+length{
            let lableCount = Int(bytes[i])
            if lableCount == 0{
                break
            };
            i+=1
        
            if let str = String(bytes: bytes[i..<i+lableCount], encoding: .utf8) {
                name.append("\(str).")
                i += lableCount
            } else {
                break
            }
        }
        
        return name
        
        
    }
    
    // 广播
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        print("Did send DNS request")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        // 处理接收到的 DNS 响应消息
        
        let ip = GCDAsyncUdpSocket.host(fromAddress: address)!
        let port = GCDAsyncUdpSocket.port(fromAddress: address)
        
        let responseBytes = [UInt8](data)
        if let requestID = calculateRequestID(ip: ip){
            
            let requestBytes = dnsRequest(id: requestID, name: reverseName(name: ip)) //得发送data才能得到回应，这个根据交互方案传值
            if(responseBytes[0] != requestBytes[0]) && (responseBytes[1] != requestBytes[1]){
                return
            }
            
            var offset = requestBytes.count
            if responseBytes[5] == 0{
                offset = 12 + reverseName(name:ip).count
            }
            offset += 2+2+2+4+2
            
            let name = decodeName(bytes: responseBytes, offset: offset, length: responseBytes.count-offset)
            print("name:\(String(describing: name?.split(separator: ".")))")
            
            try? sock.leaveMulticastGroup(mdnsIP)
            sock.close()
            
        }else{
            print("parse fail")
        }
        print(ip, port)
    }

}
