import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_detection/wifi_detection.dart';
import 'package:wifi_detection/wifi_detection_platform_interface.dart';
import 'package:wifi_detection/wifi_detection_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockWifiDetectionPlatform
    with MockPlatformInterfaceMixin
    implements WifiDetectionPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Stream<String> searchWiFiDetectionStream() {
    // TODO: implement searchWiFiDetectionStream
    throw UnimplementedError();
  }
}

void main() {
  final WifiDetectionPlatform initialPlatform = WifiDetectionPlatform.instance;

  test('$MethodChannelWifiDetection is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelWifiDetection>());
  });

  test('getPlatformVersion', () async {
    WifiDetection wifiDetectionPlugin = WifiDetection();
    MockWifiDetectionPlatform fakePlatform = MockWifiDetectionPlatform();
    WifiDetectionPlatform.instance = fakePlatform;

    expect(await wifiDetectionPlugin.getPlatformVersion(), '42');
  });
}
