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

        sceneView.overlaySKScene = overlay
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

        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        sceneView.session.pause()
    }
}

// MARK: - ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {
    func renderer(_: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return nil }

        return createFace(url: axesUrl, for: faceAnchor)
    }

    func renderer(_: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }

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

        let lookAtPointWorld = faceAnchor.lookAtPoint.toWorldCoordinate(using: faceAnchor.transform)

        let cameraCoordinate = simd_mul(simd_inverse(cameraTransform), lookAtPointWorld)

        DispatchQueue.main.async {
            // Access UI-related properties on the main thread
            let screenSize = self.sceneView.bounds.size
            let frameSize = self.sceneView.frame.size

            /* // Normalize the coordinates
             let normalizedX = CGFloat(cameraCoordinate.x / cameraCoordinate.w)
             let normalizedY = CGFloat(cameraCoordinate.y / cameraCoordinate.w)

             // Convert normalized coordinates to screen space
             let screenX = (normalizedX + 1) * 0.5 * screenSize.width
             let screenY = (1 - normalizedY) * 0.5 * screenSize.height

             let screenPoint = CGPoint(x: screenX, y: screenY) */
            // Reflecting in the XY Plane (ignoring Z coordinate)

            // Projecting onto the mobile screen
            let screenX = cameraCoordinate.y / (Float(screenSize.width) / 2) * Float(frameSize.width)
            let screenY = cameraCoordinate.x / (Float(screenSize.height) / 2) * Float(frameSize.height)

            let focusPoint = CGPoint(
                x: CGFloat(screenX).clamped(to: 0 ... screenSize.width),
                y: CGFloat(screenY).clamped(to: 0 ... screenSize.height)
            )

            completion(focusPoint)
        }
    }

    /* private func getLookOnScreen(for faceAnchor: ARFaceAnchor) -> CGPoint {
         guard let camera = sceneView.session.currentFrame?.camera else {
             fatalError("No camera transform available")
         }

         let lookAtPointWorld = faceAnchor.lookAtPoint.toWorldCoordinate(using: faceAnchor.transform)
         /* let pointOnScreen = simd_mul(simd_inverse(cameraTransform), point)

          let screenX = pointOnScreen.y / (Float(sceneView.bounds.width) / 2) * Float(sceneView.frame.width)
          let screenY = pointOnScreen.x / (Float(sceneView.bounds.height) / 2) * Float(sceneView.frame.height)

          return CGPoint(
              x: CGFloat(screenX) + sceneView.frame.width / 2,
              y: CGFloat(screenY) + sceneView.frame.height / 2
          ) */
         // Convert world coordinates to camera coordinates
         // let cameraCoordinate = camera.transform.inverse * lookAtPointWorld
         let cameraCoordinate = simd_mul(simd_inverse(camera.transform), lookAtPointWorld)

         // Normalize the coordinates
         let normalizedX = CGFloat(cameraCoordinate.x / cameraCoordinate.w)
         let normalizedY = CGFloat(cameraCoordinate.y / cameraCoordinate.w)

         // Assuming the ARSCNView is fullscreen, we map the normalized coordinates to screen space
         let screenSize = sceneView.bounds.size
         let screenX = (normalizedX + 1) * 0.5 * screenSize.width
         let screenY = (1 - normalizedY) * 0.5 * screenSize.height

         return CGPoint(x: screenX, y: screenY)
     } */

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
