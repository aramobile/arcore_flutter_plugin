//
//  ARFaceCoreFlutterView.swift
//  AugmentedFacesExample
//
//  Created by mac on 9/11/2022.
//  Copyright © 2022 Google LLC. All rights reserved.
//


import AVFoundation
import UIKit
import Flutter

/// Demonstrates how to use ARCore Augmented Faces with SceneKit.
public final class ARFaceFlutterView: NSObject, FlutterPlatformView {
    //private var _view: ARFaceView
    private var faceViewController = FacesViewController()
    
    // MARK: - Implementation methods
    public func view() -> UIView {
        return faceViewController.view
    }
    
    init(frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?, binaryMessenger messenger: FlutterBinaryMessenger?)
    {
        //self._view = ARFaceView(frame: frame)
        //self._view.initialize()
        //self._view.loadMesh()
        //_view.backgroundColor = UIColor.green
        faceViewController = FacesViewController()
        super.init()
        if(messenger != nil) {
            let channel = FlutterMethodChannel(name: "arcore_flutter_plugin",
                                               binaryMessenger: messenger!)
            channel.setMethodCallHandler({ (call: FlutterMethodCall, result: FlutterResult) -> Void in
                switch call.method {
                case "loadMesh":
                    if let args = call.arguments as? Dictionary<String, Any> {
                        print(args)
                        let flutterData = args["textureBytes"] as! FlutterStandardTypedData
                        let textureData = Data(flutterData.data)
                        print(textureData)
                        self.faceViewController.loadMesh(data: textureData)
                    }
                    //self._view.loadMesh()
                    result("true")
                case "init":
                    let rootViewController = UIApplication.shared.windows.filter({ (w) -> Bool in
                          return w.isHidden == false
                    }).first?.rootViewController
                    //let faceViewController = FacesViewController()
                    //rootViewController?.present(self.faceViewController, animated: true, completion: nil)
                    return result("true")
                case "takeScreenshot":
                    let snapshotImagePath = self.faceViewController.snapshot()
                    result(snapshotImagePath)
                case "checkArCoreApkAvailability":
                    result("true")
                case "checkIfARCoreServicesInstalled":
                    result("true")
                default:
                    result("true")
                }
            })
        }
    }
    
    public func setTexture(path : String) -> Void {
        //_view.setTexture(path: path)
    }
}
