//
//  MDNSResolver.swift
//  wifi_detection
//
//  Created by arthur on 2024/4/5.
//

import Foundation
import CocoaAsyncSocket

class MDNSResolver: NSObject,Resolver {
    let mdnsIP:String = "224.0.0.251";
    let mdnsPort:UInt16 = 5353;
    private lazy var socket: GCDAsyncUdpSocket = {
        return GCDAsyncUdpSocket(delegate: self, delegateQueue: .main)
    }()
    private var continuation: UnsafeContinuation<String?, any Error>?
    private var timeoutTask: DispatchWorkItem?
    
    private let timeout:TimeInterval
    init(timeout: TimeInterval) {
        self.timeout = timeout
    }
    

    func resolve(ip: String) async -> String? {
    
        let name:String? = try? await withUnsafeThrowingContinuation { cont in
            
            // 设定超时时间
            let deadline = DispatchTime.now() + self.timeout
            // 创建一个延迟操作来检查超时
            self.timeoutTask = DispatchWorkItem {
                // 如果超时，取消 continuation 并返回 nil
                cont.resume(returning: nil)
            }
            
            DispatchQueue.global().asyncAfter(deadline: deadline, execute: self.timeoutTask!)
            
            do {
                try self.socket.enableReusePort(true)
                try self.socket.bind(toPort: getRandomPort())
                try self.socket.enableBroadcast(true)
                try self.socket.joinMulticastGroup(mdnsIP)
                try self.socket.beginReceiving()
            } catch {
                cont.resume(returning: nil)
                self.timeoutTask?.cancel()
            }
            
            if let requestID = calculateRequestID(ip: ip){
                let data = dnsRequest(id: requestID, name: reverseName(name: ip)) //得发送data才能得到回应，这个根据交互方案传值
                self.socket.send(Data(data), toHost: mdnsIP, port: mdnsPort, withTimeout: self.timeout, tag: 123)
                continuation = cont
            }else{
                cont.resume(returning: nil)
                self.timeoutTask?.cancel()
            }
        }
        
        return name

    }
    private func getRandomPort() -> UInt16 {
        let lowerBound: Int = 5354
        let upperBound: Int = 65535
        let port = Int.random(in: lowerBound..<upperBound)
        return UInt16(port)
    }
    
    private func calculateRequestID(ip:String ) -> Int?{
        let addrParts = ip.split(separator: ".").compactMap { Int($0) }
        
        guard addrParts.count == 4 else {
           return nil
        }
        let requestID = addrParts[2] * 255 + addrParts[3]
        return requestID;
    }

    private func reverseName(name:String) -> String{
        let addr = name.split(separator: ".")
        return "\(addr[3]).\(addr[2]).\(addr[1]).\(addr[0]).in-addr.arpa";
    }
    
    
    
    
    private func dnsRequest(id: Int, name: String) -> [UInt8] {
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
    
    private func decodeName( bytes:[UInt8],offset :Int,length :Int) ->String?{
        
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

}

extension MDNSResolver: GCDAsyncUdpSocketDelegate{
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        // 处理接收到的 DNS 响应消息
        let ip = GCDAsyncUdpSocket.host(fromAddress: address)!
        
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
            continuation?.resume(returning: name)
            self.timeoutTask?.cancel()
            try? sock.leaveMulticastGroup(mdnsIP)
            sock.close()
            print(sock.isClosed())
            print(socket.isClosed())
            
            
        }else{
            continuation?.resume(returning: nil)
            self.timeoutTask?.cancel()
        }
    }
    
}
