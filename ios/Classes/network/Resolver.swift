//
//  Resolver.swift
//  wifi_detection
//
//  Created by arthur on 2024/4/5.
//

import Foundation

protocol Resolver {
    func resolve(ip:String)async -> String?
}
