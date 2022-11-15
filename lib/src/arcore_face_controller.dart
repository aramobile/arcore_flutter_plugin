import 'package:flutter/services.dart';

import '../arcore_flutter_plugin.dart';

class ArCoreFaceController {
  ArCoreFaceController(
      {int? id, this.enableAugmentedFaces = false, this.debug = false}) {
    _channel = MethodChannel('arcore_flutter_plugin');
    _channel.setMethodCallHandler(_handleMethodCalls);
    init();
  }

  final bool enableAugmentedFaces;
  final bool debug;
  late MethodChannel _channel;
  StringResultHandler? onError;

  init() async {
    try {
      await _channel.invokeMethod<void>('init', {
        'enableAugmentedFaces': enableAugmentedFaces,
      });
    } on PlatformException catch (ex) {
      print(ex.message);
    }
  }

  Future<dynamic> _handleMethodCalls(MethodCall call) async {
    if (debug) {
      print('_platformCallHandler call ${call.method} ${call.arguments}');
    }
    switch (call.method) {
      case 'onError':
        onError?.call(call.arguments);
        break;
      default:
        if (debug) {
          print('Unknown method ${call.method}');
        }
    }
    return Future.value();
  }

  Future<void> loadMesh(
      {required Uint8List textureBytes, String? skin3DModelFilename}) {
    return _channel.invokeMethod('loadMesh', {
      'textureBytes': textureBytes,
      'skin3DModelFilename': skin3DModelFilename
    });
  }

  void dispose() {
    _channel.invokeMethod<void>('dispose');
  }

  Future<String> snapshot() async {
    final String path = await _channel.invokeMethod('takeScreenshot');

    return path;
  }
}
