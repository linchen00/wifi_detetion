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
//            let parser = MDNSPacketParser()
//            parser.startListening()
            let networkTool =  NetworkTool()
            networkTool.udpBroadcast(ip: "192.168.0.118")
            Thread.sleep(forTimeInterval: 10)
            print("finish")
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
