/*
 * Copyright 2019 Google LLC. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import AVFoundation
import CoreMedia
import CoreMotion
import SceneKit
import UIKit

import ARCoreAugmentedFaces
import Flutter

/// Demonstrates how to use ARCore Augmented Faces with SceneKit.
public final class FacesViewController: UIViewController {
    private var arFaceView : ARFaceView = ARFaceView(frame: CGRect.zero)
  // MARK: - Implementation methods
  /*
    public override func viewDidLoad() {
        let arFaceView = ARFaceFlutterView(frame: view.frame, viewIdentifier: 1243434, arguments: nil, binaryMessenger: nil)
        view.addSubview(arFaceView.view())
        //arFaceView.initialize()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            // your code here
            arFaceView.setTexture(path: "Face.scnassets/canonical_fr_last version.png")
        }
    }*/


    override public func loadView() {
        view = UIView(frame: UIScreen.main.bounds)
        arFaceView = ARFaceView(frame: view.frame)
        view.addSubview(arFaceView)
        arFaceView.initialize()
        /*
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            // your code here
            arFaceView.setTexture(path: "Face.scnassets/half-face.mrclast_50_png.png")
        }*/
    }

    public func loadMesh(data: Data) {
        arFaceView.loadMesh(data: data)
    }

    public func snapshot() -> String? {
        return arFaceView.snapshot()
    }

    public func dispose() {
        arFaceView.dispose()
        arFaceView.removeFromSuperview()
    }
}
