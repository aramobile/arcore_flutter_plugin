//
//  ARFaceView.swift
//  AugmentedFacesExample
//
//  Created by mac on 3/11/2022.
//  Copyright © 2022 Google LLC. All rights reserved.
//


import AVFoundation
import CoreMedia
import CoreMotion
import SceneKit
import UIKit

//import ARCore

import ARCoreAugmentedFaces

/// Demonstrates how to use ARCore Augmented Faces with SceneKit.
public final class ARFaceView: UIView {
  // MARK: - Member Variables
  private var needToShowFatalError = false
  private var alertWindowTitle = "Nothing"
  private var alertMessage = "Nothing"
  private var viewDidAppearReached = false

  // MARK: - Camera / Scene properties

  private var captureDevice: AVCaptureDevice?
  private var captureSession: AVCaptureSession?
  private var videoFieldOfView = Float(0)
  private lazy var cameraImageLayer = CALayer()
  private lazy var sceneView = SCNView()
  private lazy var sceneCamera = SCNCamera()
  private lazy var motionManager = CMMotionManager()

  // MARK: - Face properties

  private var faceSession: GARAugmentedFaceSession?
  private lazy var faceMeshConverter = FaceMeshGeometryConverter()
  private lazy var faceNode = SCNNode()
  private lazy var faceTextureNode = SCNNode()
  private lazy var faceOccluderNode = SCNNode()
  private var faceTextureMaterial = SCNMaterial()
  private var faceOccluderMaterial = SCNMaterial()
  //private var noseTipNode: SCNNode?
  //private var foreheadLeftNode: SCNNode?
  //private var foreheadRightNode: SCNNode?
    
    private var hasTexture = false
    
    public func initialize() {
        if !setupScene() {
          return
        }
        if !setupCamera() {
          return
        }
        if !setupMotion() {
          return
        }

        do {
          faceSession = try GARAugmentedFaceSession(fieldOfView: videoFieldOfView)
        } catch {
          alertWindowTitle = "A fatal error occurred."
          alertMessage = "Failed to create session. Error description: \(error)"
          popupAlertWindowOnError(alertWindowTitle: alertWindowTitle, alertMessage: alertMessage)
        }
    }

  /// Create the scene view from a scene and supporting nodes, and add to the view.
  /// The scene is loaded from 'fox_face.scn' which was created from 'canonical_face_mesh.fbx', the
  /// canonical face mesh asset.
  /// https://developers.google.com/ar/develop/developer-guides/creating-assets-for-augmented-faces
  /// - Returns: true when the function has fatal error; false when not.
  private func setupScene() -> Bool {
    guard let scene = SCNScene(named: "Face.scnassets/fox_face.scn")/*,
      let modelRoot = scene.rootNode.childNode(withName: "asset", recursively: false)*/
    else {
      alertWindowTitle = "A fatal error occurred."
      alertMessage = "Failed to load face scene!"
      popupAlertWindowOnError(alertWindowTitle: alertWindowTitle, alertMessage: alertMessage)
      return false
    }

    // SceneKit uses meters for units, while the canonical face mesh asset uses centimeters.
    //modelRoot.simdScale = simd_float3(1, 1, 1) * 0.01
    //foreheadLeftNode = modelRoot.childNode(withName: "FOREHEAD_LEFT", recursively: true)
    //foreheadRightNode = modelRoot.childNode(withName: "FOREHEAD_RIGHT", recursively: true)
    //noseTipNode = modelRoot.childNode(withName: "NOSE_TIP", recursively: true)

    //faceNode.addChildNode(faceTextureNode)
    //faceNode.addChildNode(faceOccluderNode)
    scene.rootNode.addChildNode(faceNode)

    let cameraNode = SCNNode()
    cameraNode.camera = sceneCamera
    scene.rootNode.addChildNode(cameraNode)

    sceneView.scene = scene
    sceneView.frame = self.bounds
    sceneView.delegate = self
    sceneView.rendersContinuously = true
    sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    sceneView.backgroundColor = .clear
    // Flip 'x' to mirror content to mimic 'selfie' mode
    sceneView.layer.transform = CATransform3DMakeScale(-1, 1, 1)
    self.addSubview(sceneView)

    //let faceImage = UIImage(named: "Face.scnassets/canonical_facemrc.png")
    //faceTextureMaterial.diffuse.contents = faceImage
    // SCNMaterial does not premultiply alpha even with blendMode set to alpha, so do it manually.
    //faceTextureMaterial.shaderModifiers = [SCNShaderModifierEntryPoint.fragment: "_output.color.rgb *= _output.color.a;"]
    faceOccluderMaterial.colorBufferWriteMask = []

    return true
  }

    public func loadMesh(data : Data) -> Void {
      if(hasTexture == false) {
        faceNode.addChildNode(faceTextureNode)
        faceNode.addChildNode(faceOccluderNode)
        hasTexture = true
      }
      faceTextureMaterial.diffuse.contents = data
    }

  /// Setup a camera capture session from the front camera to receive captures.
  /// - Returns: true when the function has fatal error; false when not.
  private func setupCamera() -> Bool {
    guard
      let device =
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    else {
      alertWindowTitle = "A fatal error occurred."
      alertMessage = "Failed to get device from AVCaptureDevice."
      popupAlertWindowOnError(alertWindowTitle: alertWindowTitle, alertMessage: alertMessage)
      return false
    }

    guard
      let input = try? AVCaptureDeviceInput(device: device)
    else {
      alertWindowTitle = "A fatal error occurred."
      alertMessage = "Failed to get device input from AVCaptureDeviceInput."
      popupAlertWindowOnError(alertWindowTitle: alertWindowTitle, alertMessage: alertMessage)
      return false
    }

    let output = AVCaptureVideoDataOutput()
    output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInteractive))

    let session = AVCaptureSession()
    session.sessionPreset = .high
    session.addInput(input)
    session.addOutput(output)
    captureSession = session
    captureDevice = device

    videoFieldOfView = captureDevice?.activeFormat.videoFieldOfView ?? 0

    cameraImageLayer.contentsGravity = .center
    cameraImageLayer.frame = self.bounds
      self.layer.insertSublayer(cameraImageLayer, at: 0)

    // Start capturing images from the capture session once permission is granted.
    getVideoPermission(permissionHandler: { granted in
      guard granted else {
        NSLog("Permission not granted to use camera.")
        self.alertWindowTitle = "Alert"
        self.alertMessage = "Permission not granted to use camera."
        self.popupAlertWindowOnError(
          alertWindowTitle: self.alertWindowTitle, alertMessage: self.alertMessage)
        return
      }
        self.captureSession?.startRunning()
    })

    return true
  }

  /// Start receiving motion updates to determine device orientation for use in the face session.
  /// - Returns: true when the function has fatal error; false when not.
  private func setupMotion() -> Bool {
    //NSLog("------- setupMotion function")
    guard motionManager.isDeviceMotionAvailable else {
      alertWindowTitle = "Alert"
      alertMessage = "Device does not have motion sensors."
      popupAlertWindowOnError(alertWindowTitle: alertWindowTitle, alertMessage: alertMessage)
      return false
    }
    motionManager.deviceMotionUpdateInterval = 0.01
    motionManager.startDeviceMotionUpdates()

    return true
  }

  /// Get permission to use device camera.
  ///
  /// - Parameters:
  ///   - permissionHandler: The closure to call with whether permission was granted when
  ///     permission is determined.
  private func getVideoPermission(permissionHandler: @escaping (Bool) -> Void) {
    //NSLog("------- getVideoPermission function")
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      permissionHandler(true)
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video, completionHandler: permissionHandler)
    default:
      permissionHandler(false)
    }
  }

  /// Update a region node's transform with the transform from the face session. Ignore the scale
  /// on the passed in transform to preserve the root level unit conversion.
  ///
  /// - Parameters:
  ///   - transform: The world transform to apply to the node.
  ///   - regionNode: The region node on which to apply the transform.
  private func updateTransform(_ transform: simd_float4x4, for regionNode: SCNNode?) {
    //NSLog("------- updateTransform function")
    guard let node = regionNode else {
      NSLog("In updateTransform, node is nil.")
      return
    }

    let localScale = node.simdScale
    node.simdWorldTransform = transform
    node.simdScale = localScale

    // The .scn asset (and the canonical face mesh asset that it is created from) have their
    // 'forward' (Z+) opposite of SceneKit's forward (Z-), so rotate to orient correctly.
    node.simdLocalRotate(by: simd_quatf(angle: .pi, axis: simd_float3(0, 1, 0)))
  }

  private func popupAlertWindowOnError(alertWindowTitle: String, alertMessage: String) {
        NSLog(alertMessage)
    if !self.viewDidAppearReached {
      self.needToShowFatalError = true
      // Then the process will proceed to viewDidAppear, which will popup an alert window when needToShowFatalError is true.
      return
    }
    // viewDidAppearReached is true, so we can pop up window now.
    let alertController = UIAlertController(
      title: alertWindowTitle, message: alertMessage, preferredStyle: .alert)
    alertController.addAction(
      UIAlertAction(
        title: NSLocalizedString("OK", comment: "Default action"), style: .default,
        handler: { _ in
          self.needToShowFatalError = false
        }))
    //.present(alertController, animated: true, completion: nil)
  }

    public func snapshot () -> String? {
        let snapshotImage = UIGraphicsImageRenderer(size: bounds.size).image { _ in
            drawHierarchy(in: CGRect(origin: .zero, size: bounds.size), afterScreenUpdates: true)
        }
        //let snapshotImage = sceneView.snapshot()
        if let bytes = snapshotImage.pngData() {
            let randomString = NSUUID().uuidString
            let filename = getDocumentsDirectory().appendingPathComponent("\(randomString).png")
            try? bytes.write(to: filename)
            var filenamePath = filename.absoluteString
            if let range = filenamePath.range(of:"file://") {
                 filenamePath = filenamePath.replacingCharacters(in: range, with:"")
            }
            return filenamePath
        } else {
            return nil
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }


    public func dispose() {
        captureSession?.stopRunning()
        motionManager.stopDeviceMotionUpdates()
        sceneView.removeFromSuperview()
        cameraImageLayer.removeFromSuperlayer()
    }

}

// MARK: - Camera delegate

extension ARFaceView: AVCaptureVideoDataOutputSampleBufferDelegate {

  public func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    //NSLog("------- captureOutput function")
    guard let imgBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    else {
      NSLog("In captureOutput, imgBuffer is nil.")
      return
    }
    
    guard let deviceMotion = motionManager.deviceMotion
    else {
      NSLog("In captureOutput, deviceMotion is nil.")
      return
    }

    let frameTime = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer))

    // Use the device's gravity vector to determine which direction is up for a face. This is the
    // positive counter-clockwise rotation of the device relative to landscape left orientation.
    let rotation = 2 * .pi - atan2(deviceMotion.gravity.x, deviceMotion.gravity.y) + .pi / 2
    //let rotation = 2 * Double.pi - atan2(0, 0) + Double.pi / 2
    let rotationDegrees = (UInt)(rotation * 180 / Double.pi) % 360

    faceSession?.update(with: imgBuffer, timestamp: frameTime, recognitionRotation: rotationDegrees)
  }

}

// MARK: - Scene Renderer delegate

extension ARFaceView: SCNSceneRendererDelegate {

  public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    //NSLog("------- In renderer function")
    guard let frame = faceSession?.currentFrame else {
      NSLog("In renderer, currentFrame is nil.")
      return
    }

    if let face = frame.face {
      faceTextureNode.geometry = faceMeshConverter.geometryFromFace(face)
      faceTextureNode.geometry?.firstMaterial = faceTextureMaterial
      faceOccluderNode.geometry = faceTextureNode.geometry?.copy() as? SCNGeometry
      faceOccluderNode.geometry?.firstMaterial = faceOccluderMaterial

      faceNode.simdWorldTransform = face.centerTransform
      //updateTransform(face.transform(for: .nose), for: noseTipNode)
      //updateTransform(face.transform(for: .foreheadLeft), for: foreheadLeftNode)
      //updateTransform(face.transform(for: .foreheadRight), for: foreheadRightNode)
    }

    // Set the scene camera's transform to the projection matrix for this frame.
    sceneCamera.projectionTransform = SCNMatrix4.init(
      frame.projectionMatrix(
        forViewportSize: cameraImageLayer.bounds.size,
        presentationOrientation: .portrait,
        mirrored: false,
        zNear: 0.05,
        zFar: 100)
    )

    // Update the camera image layer's transform to the display transform for this frame.
    CATransaction.begin()
    CATransaction.setAnimationDuration(0)
    cameraImageLayer.contents = frame.capturedImage as CVPixelBuffer
    cameraImageLayer.setAffineTransform(
      frame.displayTransform(
        forViewportSize: cameraImageLayer.bounds.size,
        presentationOrientation: .portrait,
        mirrored: true)
    )
    CATransaction.commit()

    // Only show AR content when a face is detected.
    sceneView.scene?.rootNode.isHidden = frame.face == nil
  }

}
