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
            Task{
               let name1 = await MDNSResolver(timeout: TimeInterval(5)).resolve(ip: "192.168.0.123")
                print("name1:\(name1)")
            }
            
           let name =  NetBIOSResolver().resolve(ip: "192.168.0.253")
            print("name:\(name)")
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
