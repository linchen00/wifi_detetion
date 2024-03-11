//
//  Wireless.swift
//  wifi_detection
//
//  Created by arthur on 2024/3/5.
//

import Foundation
import Reachability
import SystemConfiguration.CaptiveNetwork
import SystemConfiguration



struct NetInfo {
    let ip: String
    let netmask: String
}



class Wireless{
    func isWiFiConnected() -> Bool {
        do {
            let reachability = try Reachability()
            return reachability.connection == .wifi
        } catch {
            return false // 或者根据你的应用需求处理错误
        }
    }
    
    func getSSID() -> String? {
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else {
            return nil
        }
        
        for interface in interfaces {
            guard let networkInfo = CNCopyCurrentNetworkInfo(interface as CFString) as NSDictionary? else {
                continue
            }
            if let ssid = networkInfo[kCNNetworkInfoKeySSID as String] as? String {
                return ssid
            }
        }
        
        return nil
    }
    
    func getBSSID() -> String? {
        
        guard let networkInfo = getWifiInfo() else {
            return nil
        }
        
        guard let ssid = networkInfo[kCNNetworkInfoKeyBSSID as String] as? String else {
            return nil
        }
        
        return ssid
        
        
    }
    
    func getWifiInfo() -> NSDictionary? {
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else {
            return nil
        }
        
        for interface in interfaces {
            guard let networkInfo = CNCopyCurrentNetworkInfo(interface as CFString) as NSDictionary? else {
                continue
            }
            return networkInfo
        }
        
        return nil
    }

    func getInternalWifiSubnetString() -> String? {
        return getNetInfo()?.netmask
    }
    
    func getInternalWifiIpString() -> String? {
        return getNetInfo()?.ip
    }
    
    func getInternalWifiIpAddress() -> Int?{
        var ipAddressInt: Int?
        
        guard let ipAddressString = getInternalWifiIpString() else {
            return nil
        }
        
        // 将 IP 地址字符串拆分为整数数组
        let ipAddressComponents = ipAddressString.split(separator: ".").compactMap { Int($0) }
        
        // 将整数数组转换为单个整数
        if ipAddressComponents.count == 4 {
            ipAddressInt = (ipAddressComponents[0] << 24) + (ipAddressComponents[1] << 16) +
            (ipAddressComponents[2] << 8) + ipAddressComponents[3]
        }
        
        return ipAddressInt
    }
    
    func getInternalWifiSubnet() -> Int? {
        var netmaskInt: Int?
        
        guard let netmaskString = getInternalWifiSubnetString() else {
            return nil
        }
        
        // 将 IP 地址字符串拆分为整数数组
        let netmaskComponents = netmaskString.split(separator: ".").compactMap { Int($0) }
        
        // 将整数数组转换为单个整数
        if netmaskComponents.count == 4 {
            netmaskInt = (netmaskComponents[0] << 24) + (netmaskComponents[1] << 16) +
            (netmaskComponents[2] << 8) + netmaskComponents[3]
        }
        
        return netmaskInt
    }
    
    func getNetInfo() -> NetInfo? {
        
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        guard  getifaddrs(&ifaddr) == 0 else {
            return nil
        }
        defer {
            freeifaddrs(ifaddr)
        }
        var ptr = ifaddr
        
        while let current = ptr {
            let flags = Int32(current.pointee.ifa_flags)
            
            if (flags & (IFF_UP | IFF_RUNNING | IFF_LOOPBACK)) == (IFF_UP | IFF_RUNNING),
               var addr = current.pointee.ifa_addr?.pointee,
               addr.sa_family == UInt8(AF_INET),
               String(cString: current.pointee.ifa_name) == "en0",
               let address = getAddress(from: &addr),
               let netmask = getNetmask(from: &(current.pointee.ifa_netmask.pointee)){
                
                return NetInfo(ip: address, netmask: netmask)
            }
            ptr = ptr!.pointee.ifa_next
            
        }
        return nil
    }
    
    private func getAddress(from addr:inout sockaddr) -> String? {
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        guard getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                          nil, socklen_t(0), NI_NUMERICHOST) == 0 else {
            return nil
        }
        return String(cString: hostname, encoding: .utf8)
    }
    
    func getNetmask(from netmask:inout sockaddr) -> String? {
        var netmaskName = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        guard getnameinfo(&netmask, socklen_t(netmask.sa_len), &netmaskName, socklen_t(netmaskName.count),
                           nil, socklen_t(0), NI_NUMERICHOST) == 0 else {
            return nil
        }
        return String(cString: netmaskName)
    }
    
    
    
}
