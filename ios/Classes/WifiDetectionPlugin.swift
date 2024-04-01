import Flutter
import UIKit
import PlainPing

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
            let pingHelper = PingHelper(ip: "192.168.1.4")
            let isOk = pingHelper.start()
            print("isOk:\(isOk)")
//            PlainPing.ping("192.168.1.5", withTimeout: 5.0, completionBlock: { (timeElapsed:Double?, error:Error?) in
//                if let latency = timeElapsed {
//                    print("latency (ms): \(latency)")
//                }
//
//                if let error = error {
//                    print("error: \(error.localizedDescription)")
//                }
//            })
//            let parser = MDNSPacketParser()
//            parser.startListening()
//            let networkTool =  NetworkTool()
//            networkTool.udpBroadcast(ip: "192.168.1.121")
//            Thread.sleep(forTimeInterval: 1)
//            print("finish")
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
