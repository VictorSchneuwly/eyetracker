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

    private struct StoredValues {
        let point: CGPoint
        let faceAnchor: ARFaceAnchor
        let timestamp: Date
    }

    private var storedValues: [StoredValues] = []
    private let maxPoints = 10

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the view's delegate
        sceneView.delegate = self

        // Show statistics such as fps and timing information
        // sceneView.showsStatistics = true

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
        lookPoint.zPosition = 1

        overlay.addChild(lookPoint)

        sceneView.overlaySKScene = overlay

        NotificationCenter.default.addObserver(
            self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification, object: nil
        )
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

    @objc func appWillTerminate() {
        // Handle app termination, like saving data or cleaning up resources
        let calibrationScene = sceneView.overlaySKScene as? CalibrationScene
        calibrationScene?.stopCalibration()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
                    self.updateStoredValues(with: point, for: faceAnchor)
                    lookPoint.position = self.storedValues.map { $0.point }.mean().clamped(to: UIScreen.main.bounds)
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

    private func updateStoredValues(with point: CGPoint, for faceAnchor: ARFaceAnchor) {
        if storedValues.count >= maxPoints {
            storedValues.removeFirst()
        }
        storedValues.append(StoredValues(point: point, faceAnchor: faceAnchor, timestamp: Date()))
    }
}

// MARK: - CalibrationDelegate

extension ViewController: CalibrationDelegate {
    func getCalibrationData(
        of name: String, for target: CGPoint, position: HeadPosition, distance: PositionToScreen
    ) -> [CalibrationData]? {
        if storedValues.isEmpty { return nil }

        return storedValues.map { storedValue in
            CalibrationData(
                username: name,
                deviceName: Device.name ?? "unknown",
                position: position,
                distance: distance,
                timestamp: storedValue.timestamp,
                targetPoint: target,
                gazePoint: storedValue.point,
                faceTransform: storedValue.faceAnchor.transform,
                rightEyeTransform: storedValue.faceAnchor.rightEyeTransform,
                leftEyeTransform: storedValue.faceAnchor.leftEyeTransform,
                lookAtPoint: storedValue.faceAnchor.lookAtPoint
            )
        }
    }

    func onCalibrationStateChange(state: CalibrationState) {
        print("Calibration state changed to:\n\(state)")

        switch state {
        case .calibration:
            // Hide look point during calibration
            sceneView.overlaySKScene?.childNode(withName: "lookPoint")?.isHidden = true
        default:
            // Show look point after calibration
            sceneView.overlaySKScene?.childNode(withName: "lookPoint")?.isHidden = false
        }
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
