import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'wifi_detection_method_channel.dart';

abstract class WifiDetectionPlatform extends PlatformInterface {
  /// Constructs a WifiDetectionPlatform.
  WifiDetectionPlatform() : super(token: _token);

  static final Object _token = Object();

  static WifiDetectionPlatform _instance = MethodChannelWifiDetection();

  /// The default instance of [WifiDetectionPlatform] to use.
  ///
  /// Defaults to [MethodChannelWifiDetection].
  static WifiDetectionPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WifiDetectionPlatform] when
  /// they register themselves.
  static set instance(WifiDetectionPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Stream<String> searchWiFiDetectionStream() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
