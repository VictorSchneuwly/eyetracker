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
    private var eyeTracker = AREyeTracker()
    private var points: [CGPoint] = []
    private let maxPoints = 10

    private var lastFaceAnchor: ARFaceAnchor?

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
        let overlay = CalibrationScene(size: view.bounds.size)
        overlay.scaleMode = .resizeFill
        overlay.calibrationDelegate = self

        let lookPoint = SKShapeNode(circleOfRadius: 20)
        lookPoint.name = "lookPoint"
        lookPoint.fillColor = .yellow
        lookPoint.strokeColor = .yellow

        overlay.addChild(lookPoint)

        let testPoint = SKShapeNode(circleOfRadius: 20)
        testPoint.name = "testPoint"
        testPoint.fillColor = .yellow
        testPoint.strokeColor = .yellow

        overlay.addChild(testPoint)

        sceneView.overlaySKScene = overlay

        startCalibration()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard ARFaceTrackingConfiguration.isSupported else {
            // TODO: add pop up to inform the user
            fatalError("Face tracking is not supported on this device")
        }

        // Create a session configuration
        let configuration = ARFaceTrackingConfiguration()
        configuration.maximumNumberOfTrackedFaces = 1
        configuration.isLightEstimationEnabled = true
        configuration.worldAlignment = .camera

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
        guard let faceAnchor = anchor as? ARFaceAnchor else {
            return nil
        }

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
            DispatchQueue.main.async {
                // Access UI-related properties on the main thread
                let point = self.eyeTracker.getLookOnScreen(using: faceAnchor)
                if let point = point {
                    self.updatePoints(with: point)
                    lookPoint.position = self.points.mean().clamped(to: UIScreen.main.bounds)
                }
            }
        }
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

    private func updatePoints(with point: CGPoint) {
        if points.count >= maxPoints {
            points.removeFirst()
        }
        points.append(point)
    }
}

// MARK: - CalibrationDelegate

extension ViewController: CalibrationDelegate {
    func startCalibration() {
        guard let overlay = sceneView.overlaySKScene as? CalibrationScene else { return }
        overlay.startCalibration()
    }

    func stopCalibration() {
        guard let overlay = sceneView.overlaySKScene as? CalibrationScene else { return }
        overlay.stopCalibration()
    }

    func getCalibrationData(for target: CGPoint) -> CalibrationData? {
        if points.isEmpty {
            return nil
        }

        guard let faceAnchor = lastFaceAnchor else { return nil }
        // TODO: mean or last point?
        let gazePoint = points.mean()
        return CalibrationData(
            targetPoint: target,
            gazePoint: gazePoint,
            faceTransform: faceAnchor.transform,
            rightEyeTransform: faceAnchor.rightEyeTransform,
            leftEyeTransform: faceAnchor.leftEyeTransform
        )
    }
}

// MARK: - face handling

private func createFace(url: URL, for anchor: ARFaceAnchor) -> SCNNode? {
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
