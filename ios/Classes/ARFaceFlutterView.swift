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
        faceViewController = FacesViewController()
        super.init()
        if(messenger != nil) {
            let channel = FlutterMethodChannel(name: "arcore_flutter_plugin\(viewId)",
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
                    result(true)
                case "init":
                    return result(true)
                case "takeScreenshot":
                    let snapshotImagePath = self.faceViewController.snapshot()
                    result(snapshotImagePath)
                default:
                    result(true)
                }
            })
        }
    }
}
