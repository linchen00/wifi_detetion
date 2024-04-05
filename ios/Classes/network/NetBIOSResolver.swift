//
//  NetBIOSResolver.swift
//  wifi_detection
//
//  Created by arthur on 2024/4/5.
//

import TOSMBClient

import Foundation

class NetBIOSResolver:Resolver {
    
    func resolve(ip: String) -> String? {
        let netBIOSNameService = TONetBIOSNameService()
        
        return netBIOSNameService.lookupNetworkName(forIPAddress: ip)
    }

}
