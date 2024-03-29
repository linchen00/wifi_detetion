
import 'wifi_detection_platform_interface.dart';

class WifiDetection {
  Future<String?> getPlatformVersion() {
    return WifiDetectionPlatform.instance.getPlatformVersion();
  }

  Stream<String> searchWiFiDetectionStream() {
    return WifiDetectionPlatform.instance.searchWiFiDetectionStream();
  }
}
