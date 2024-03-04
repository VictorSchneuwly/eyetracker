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

    private let axesUrl = Bundle.main.url(forResource: "art.scnassets/axes", withExtension: "scn")!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the view's delegate
        sceneView.delegate = self
        // sceneView.session.delegate = self

        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true

        // Set the scene to the view
        sceneView.scene = SCNScene()

        // print("Face tracking is supported: \(ARFaceTrackingConfiguration.isSupported)")
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
        // Create and configure a node for the anchor added to the view's session.

        if let faceAnchor = anchor as? ARFaceAnchor {
            let node = FaceNode(url: axesUrl)
            node.update(with: faceAnchor)
            return node
        }

        // if it is not a face: add a box on the anchor
        let node = SCNNode()
        node.geometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        return node
    }

    func renderer(_: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceNode = node as? FaceNode,
              let faceAnchor = anchor as? ARFaceAnchor
        else {
            return
        }

        faceNode.update(with: faceAnchor)
    }

    func session(_: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        guard let error = error as? ARError else {
            return
        }

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
