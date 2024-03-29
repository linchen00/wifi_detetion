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
    
    let udpTimeOut:TimeInterval = TimeInterval(40);
    let mdnsIP:String = "224.0.0.251";

    let mdnsPort:UInt16 = 5353;
    
    let group = DispatchGroup()
    /// UDP
    private lazy var udp: GCDAsyncUdpSocket = {
        let socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: .main)
//        socket.setIPv4Enabled(true)
//        socket.setPreferIPv4()
//        socket.setIPv6Enabled(false)
        print("ipv4:\(socket.isIPv4Preferred())")
        print("ipv4:\(socket.isIPv4Enabled())")
        print("ipv6:\(socket.isIPv6Preferred())")
        print("ipv6:\(socket.isIPv6Enabled())")
        return socket
        
    }()
    
    /// 指定设备发送广播
    func udpBroadcast(ip: String) {
        self.udpDefalut()
        self.boardDeviceInfo(ip: ip)
        
//        let timeoutResult = group.wait(timeout: .now() + .seconds(20)) // 等待所有任务执行完成或超时
//
//        if timeoutResult == .timedOut {
//            print("Timeout: Some tasks are not finished.")
//        } else {
//            print("All tasks finished.")
//        }
    }
    /// deviceInfo
    func boardDeviceInfo(ip: String) {
        let addrParts = ip.split(separator: ".").compactMap { Int($0) }
        
        guard addrParts.count == 4 else {
            print("Invalid IP address format")
            // 处理无效 IP 地址的情况
           return
        }
        let requestID = addrParts[2] * 255 + addrParts[3]
        
        print("reverseName:\(reverseName(name: ip))")
        
        
        let data = dnsRequest(id: requestID, name: reverseName(name: ip)) //得发送data才能得到回应，这个根据交互方案传值
        
        
        
        print("data:\(data)")
        
        self.udp.send(Data(data), toHost: mdnsIP, port: mdnsPort, withTimeout: self.udpTimeOut, tag: 0)
        group.enter()
    }
    /// UDP 默认设置
    func udpDefalut() {
        
        if self.udp.localPort() != self.mdnsPort {//self.udpPort为当前绑定的端口，判断是否已经绑定过
            do {
                try self.udp.enableReusePort(true)
                try self.udp.bind(toPort: mdnsPort)
                try self.udp.enableBroadcast(true)
                try self.udp.joinMulticastGroup(mdnsIP)
                try self.udp.beginReceiving()
            } catch let error {
                NSLog("udp失败\(error)")
            }
        }
    }
    /// 暂停广播
    func udpPauseReceiving() {
        self.udp.pauseReceiving()
    }
    func reverseName(name:String) -> String{
        let addr = name.split(separator: ".")
        return "\(addr[3]).\(addr[2]).\(addr[1]).\(addr[0]).in-addr.arpa";
    }
    
    func dnsRequest(id: Int, name: String) -> [UInt8] {
        var byteArray = [UInt8]()
        
        
        // ID
        byteArray += [UInt8(id >> 8), UInt8(id & 0xff)]
        
        print("byteArray:\(byteArray)")
        
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
    
    // 广播
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        print("Did send DNS request")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        // 处理接收到的 DNS 响应消息
        print("Did receive DNS response: \(data)")
        let ip = GCDAsyncUdpSocket.host(fromAddress: address)!
        let port = GCDAsyncUdpSocket.port(fromAddress: address)
        print(ip, port)
    }

}
