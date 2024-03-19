//
//  ViewController.swift
//  EyeTracker
//
//  Created by Victor Schneuwly on 25.02.2024.
//

import ARKit
import SceneKit
import SpriteKit
import UIKit

class ViewController: UIViewController {
    @IBOutlet var sceneView: ARSCNView!

    private let axesUrl = Bundle.main.url(forResource: "axes", withExtension: "scn")!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the view's delegate
        sceneView.delegate = self
        // sceneView.session.delegate = self

        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true

        // Set the scene to the view
        sceneView.scene = SCNScene()

        // Add an overlay to the scene view
        let overlay = SKScene(size: view.bounds.size)
        overlay.scaleMode = .resizeFill

        let lookPoint = SKShapeNode(circleOfRadius: 20)
        lookPoint.name = "lookPoint"
        lookPoint.fillColor = .red
        lookPoint.strokeColor = .red

        overlay.addChild(lookPoint)

        let testPoint = SKShapeNode(circleOfRadius: 20)
        testPoint.name = "testPoint"
        testPoint.fillColor = .yellow
        testPoint.strokeColor = .yellow

        overlay.addChild(testPoint)

        let lineNode = createLineNode(from: simd_float3(0, 0, 0), to: simd_float3(0, 0, 1))
        sceneView.scene.rootNode.addChildNode(lineNode)

        sceneView.overlaySKScene = overlay

        /* // launch the test func in a new thread after 5 seconds
         DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
             print("test")
             // self.test(cameraTranform: self.sceneView.session.currentFrame!.camera.transform)
             // Create the translation matrix
             var translation = matrix_identity_float4x4
             translation.columns.3.z = -1

             // Combine the matrix with the camera transform
             // When you create an anchor using this new matrix,
             // ARKit will place the anchor at the correct position in 3D space relative to the camera
             let transform = self.sceneView.session.currentFrame!.camera.transform * translation

             // Here you add an anchor to the session.
             // The anchor is now a permanent feature in your 3D world (until you remove it).
             // Each frame tracks this anchor and recalculates the transformation matrices of the anchors
             // and the camera using the device’s new position and orientation.
             let anchor = ARAnchor(transform: transform)
             self.sceneView.session.add(anchor: anchor)
         } */
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard ARFaceTrackingConfiguration.isSupported else {
            // TODO: add pop up to inform the user
            fatalError("Face tracking is not supported on this device")
        }

        // Create a session configuration
        let configuration = ARFaceTrackingConfiguration()
        if #available(iOS 13.0, *) {
            configuration.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces
        }
        configuration.isLightEstimationEnabled = true
        // configuration.worldAlignment = .camera

        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        sceneView.session.pause()
    }

    func sphere(at anchor: ARAnchor) -> SCNNode? {
        // add a sphere at the anchor
        let sphere = SCNSphere(radius: 0.1)
        let sphereNode = SCNNode(geometry: sphere)
        // make the sphere blue
        sphere.firstMaterial?.diffuse.contents = UIColor.blue
        print("Added sphere at \(anchor.transform)")
        // also project it on the overlay
        // using projectPoint to get the 2D point on the screen
        let projectedPoint = sceneView.projectPoint(sphereNode.position)
        print("Projected point: \(projectedPoint)")
        // update testPoint
        sceneView.overlaySKScene?
            .childNode(withName: "testPoint")?
            .position = CGPoint(x: CGFloat(projectedPoint.x), y: CGFloat(projectedPoint.y))
        return sphereNode
    }
}

// MARK: - ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {
    func renderer(_: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let faceAnchor = anchor as? ARFaceAnchor else {
            return sphere(at: anchor)
        }

        return createFace(url: axesUrl, for: faceAnchor)
    }

    func renderer(_: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else {
            return
        }
        DispatchQueue.main.async {
            // Access UI-related properties on the main thread
            let screenSize = self.sceneView.bounds.size
            // update the test point
            let projectedPoint = self.sceneView.projectPoint(node.position)
            // change the y axis to be size - y
            let point = CGPoint(x: CGFloat(projectedPoint.x), y: screenSize.height - CGFloat(projectedPoint.y))
            self.sceneView.overlaySKScene?
                .childNode(withName: "testPoint")?
                .position = point
        }

        node.enumerateChildNodes { child, _ in
            if child.name == "left" {
                child.simdTransform = faceAnchor.leftEyeTransform
            } else if child.name == "right" {
                child.simdTransform = faceAnchor.rightEyeTransform
            }
        }

        // update the look point on the overlay
        if let lookPoint = sceneView.overlaySKScene?.childNode(withName: "lookPoint") {
            getLookOnScreen(for: faceAnchor) { point in
                print("New look point: \(point)")
                lookPoint.position = point
            }
        }
    }

    private func getLookOnScreen(for faceAnchor: ARFaceAnchor, completion: @escaping (CGPoint) -> Void) {
        guard let cameraTransform = sceneView.session.currentFrame?.camera.transform else {
            fatalError("No camera transform available")
        }

        /* let lookAtPointWorld = faceAnchor.lookAtPoint.toWorldCoordinate(using: faceAnchor.transform)

         let cameraCoordinate = simd_mul(simd_inverse(cameraTransform), lookAtPointWorld) */

        DispatchQueue.main.async {
            // Access UI-related properties on the main thread
            let screenSize = self.sceneView.bounds.size

            let eyeWorldPosition =
                simd_make_float3(faceAnchor.rightEyeTransform.columns.3).toWorldCoordinate(using: faceAnchor.transform)

            // Forward direction in world space - assuming the eye is looking along the negative Z-axis
            let eyeWorldDirection =
                simd_make_float3(faceAnchor.rightEyeTransform.columns.2).toWorldCoordinate(using: faceAnchor.transform)

            let eyeCameraPosition = eyeWorldPosition.toLocalCoordinate(using: cameraTransform)
            let eyeCameraDirection = eyeWorldDirection.toLocalCoordinate(using: cameraTransform)

            let intersection =
                self.intersectionWithZEqualZero(eyePosition: eyeCameraPosition, eyeDirection: eyeCameraDirection)

            // put the intersection in world coordinates
            let intersectionWorld = intersection.toWorldCoordinate(using: cameraTransform)

            updateLineNode(from: eyeWorldPosition,
                           to: intersectionWorld, on: self.sceneView)

            let point = self.sceneView.projectPoint(SCNVector3(intersectionWorld))

            let focusPoint = CGPoint(
                x: CGFloat(point.x).clamped(to: 0 ... screenSize.width),
                y: screenSize.height - CGFloat(point.y).clamped(to: 0 ... screenSize.height)
            )

            completion(focusPoint)
        }
    }

    private func eyePositionAndDirectionInCameraSpace(
        faceAnchor: ARFaceAnchor, cameraTransform: simd_float4x4
    ) -> (position: simd_float3, direction: simd_float3) {
        let eyeWorldPosition =
            simd_make_float3(faceAnchor.rightEyeTransform.columns.3).toWorldCoordinate(using: faceAnchor.transform)

        // Forward direction in world space - assuming the eye is looking along the negative Z-axis
        let eyeWorldDirection =
            simd_make_float3(faceAnchor.rightEyeTransform.columns.2).toWorldCoordinate(using: faceAnchor.transform)

        let eyeCameraPosition = eyeWorldPosition.toLocalCoordinate(using: cameraTransform)
        let eyeCameraDirection = eyeWorldDirection.toLocalCoordinate(using: cameraTransform)

        return (eyeCameraPosition, eyeCameraDirection)
    }

    private func intersectionWithZEqualZero(eyePosition: simd_float3, eyeDirection: simd_float3) -> simd_float3 {
        if eyeDirection.z == 0 {
            // If the eye is looking parallel to the z=0 plane, there is no intersection
            print("Eye is looking parallel to the z=0 plane")
            return simd_float3(0, 0, 0)
        }

        // Assuming eyeDirection.z is not 0, calculate the intersection with the z=0 plane
        let dir = -eyePosition.z / eyeDirection.z

        // Use the parameter t to find the intersection point
        return eyePosition + dir * eyeDirection
    }

    // MARK: - session delegate

    func session(_: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        guard let error = error as? ARError else { return }

        let errorWithInfo = "An error occurred: \(error.localizedDescription)"
        print(errorWithInfo)
    }

    func sessionWasInterrupted(_: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        sceneView.session.run(session.configuration!,
                              options: [.resetTracking,
                                        .removeExistingAnchors])
    }
}

// MARK: - face handling

func createFace(url: URL, for anchor: ARFaceAnchor) -> SCNNode? {
    let face = SCNReferenceNode(url: url)
    let leftEye = SCNReferenceNode(url: url)
    let rightEye = SCNReferenceNode(url: url)

    leftEye?.name = "left"
    rightEye?.name = "right"

    // load everything
    face?.load()
    leftEye?.load()
    rightEye?.load()

    // add the eyes to the face
    if let leftEye = leftEye {
        leftEye.simdTransform = anchor.leftEyeTransform
        face?.addChildNode(leftEye)
    }
    if let rightEye = rightEye {
        rightEye.simdTransform = anchor.rightEyeTransform
        face?.addChildNode(rightEye)
    }

    return face
}

/*
 func projectRightEyeGazeToScreen(using faceAnchor: ARFaceAnchor, in sceneView: ARSCNView) -> CGPoint? {
 // 1. Obtain the Right Eye Transform
 let rightEyeTransform = faceAnchor.rightEyeTransform

 // 2. Define a Forward Direction from the Right Eye
 // We choose a point 1 meter in front of the eye for this example
 var forwardVector = simd_float4(0, 0, -1, 0) // Assuming the eye is looking along the negative Z-axis
 let translation = simd_make_float4x4(simd_float4(0, 0, -1, 1)) // Translate 1 meter in front of the eye
 let transformedPoint = simd_mul(rightEyeTransform, translation) * forwardVector

 // 3. Project the Point onto the Screen
 let projectedPoint = sceneView.projectPoint(SCNVector3(transformedPoint.x, transformedPoint.y, transformedPoint.z))

 // Convert the SCNVector3 result to CGPoint, noting that projectedPoint.z
 // is depth and can be ignored for 2D screen coordinates
 let screenPoint = CGPoint(x: CGFloat(projectedPoint.x), y: CGFloat(projectedPoint.y))

 return screenPoint
 }
 */
