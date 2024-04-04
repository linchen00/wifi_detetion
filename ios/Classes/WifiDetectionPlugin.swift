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
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
