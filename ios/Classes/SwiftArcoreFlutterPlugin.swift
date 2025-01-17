import Flutter
import UIKit

public class SwiftArcoreFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "arcore_flutter_plugin", binaryMessenger: registrar.messenger())

    let factory = IosARViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "arcore_flutter_plugin")
    
    let channelUtils = FlutterMethodChannel(name: "arcore_flutter_plugin/utils", binaryMessenger: registrar.messenger())
    channelUtils.setMethodCallHandler({ (call: FlutterMethodCall, result: FlutterResult) -> Void in          
        switch call.method {
            case "checkArCoreApkAvailability":
                result(true)
            case "checkIfARCoreServicesInstalled":
                result(true)
            default:
                result(FlutterMethodNotImplemented)
        }
    })
  }
}
