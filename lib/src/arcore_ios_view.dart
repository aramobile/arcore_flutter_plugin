import 'package:arcore_flutter_plugin/src/arcore_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef PlatformViewCreatedCallback = void Function(int id);

class ArCoreiOSView extends UiKitView {
  final PlatformViewCreatedCallback? onPlatformViewCreated;
  final String viewType;

  ArCoreiOSView({Key? key, required this.viewType, this.onPlatformViewCreated})
      : super(
          viewType: viewType,
          onPlatformViewCreated: onPlatformViewCreated,
          creationParams: <String, dynamic>{},
          creationParamsCodec: const StandardMessageCodec(),
        );
}
