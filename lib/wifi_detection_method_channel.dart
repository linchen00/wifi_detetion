import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'wifi_detection_platform_interface.dart';

/// An implementation of [WifiDetectionPlatform] that uses method channels.
class MethodChannelWifiDetection extends WifiDetectionPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('wifi_detection');

  @visibleForTesting
  final searchDevicesEventChannel = const EventChannel('wifi_detection_search_devices');


  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Stream<String> searchWiFiDetectionStream() {
    return searchDevicesEventChannel.receiveBroadcastStream().map((event) => event.toString());
  }
}
