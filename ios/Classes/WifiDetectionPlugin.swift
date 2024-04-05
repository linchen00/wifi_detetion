import Flutter
import UIKit

public class WifiDetectionPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "wifi_detection", binaryMessenger: registrar.messenger())
        let instance = WifiDetectionPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        let searchChannel = FlutterEventChannel(name: "wifi_detection_search_devices", binaryMessenger: registrar.messenger())
        searchChannel.setStreamHandler(SearchDevicesHandlerImpl())
        
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            let name = getHostName(for: "192.168.0.123")
            print("name:\(name)")
    
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func getHostName(for ipAddress: String) -> String? {
        var hostname = ""

        // 将 IP 地址转换为 C 字符串
        let cIpAddress = ipAddress.cString(using: .utf8)

        // 将 C 字符串转换为 in_addr 结构体
        var addr = in_addr()
        if let cIpAddress = cIpAddress {
            inet_aton(cIpAddress, &addr)
        } else {
            return nil
        }

        // 通过 IP 地址获取主机名
        guard let host = gethostbyaddr(&addr, socklen_t(MemoryLayout<in_addr>.size), AF_INET),
              let hostnamePtr = host.pointee.h_name else {
            return nil
        }

        // 从返回的 host 结构体中获取主机名

        return String(cString: hostnamePtr)
    }
}
