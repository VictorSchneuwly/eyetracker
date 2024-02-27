//
//  ViewController.swift
//  FaceTracker
//
//  Created by Victor Schneuwly on 25.02.2024.
//

import ARKit
import SpriteKit
import UIKit

class ViewController: UIViewController {
    @IBOutlet var sceneView: ARSKView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the view's delegate
        sceneView.delegate = self

        // Show statistics such as fps and node count
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true

        // Load the SKScene from 'Scene.sks'
        if let scene = SKScene(fileNamed: "Scene") {
            sceneView.presentScene(scene)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard ARFaceTrackingConfiguration.isSupported else {
            // TODO: add pop up to inform the user
            fatalError("Face tracking is not supported on this device")
            return
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

// MARK: - ARSKViewDelegate

extension ViewController: ARSKViewDelegate {
    func view(_: ARSKView, nodeFor anchor: ARAnchor) -> SKNode? {
        // Create and configure a node for the anchor added to the view's session.
        if let faceAnchor = anchor as? ARFaceAnchor {
            // Create a node for the face anchor
            let faceNode = SKShapeNode()

            let eyeNode = SKLabelNode(text: "👁")
            // use the faceAnchor to get the position of the eyes
            let leftEyePosition = faceAnchor.leftEyeTransform.columns.3
            let rightEyePosition = faceAnchor.rightEyeTransform.columns.3
            eyeNode.position = CGPoint(x: CGFloat(leftEyePosition.x), y: CGFloat(-leftEyePosition.y))
            faceNode.addChild(eyeNode)

            // use a cheese emohi for the right eye
            let rightEyeNode = SKLabelNode(text: "🧀")
            rightEyeNode.position = CGPoint(x: CGFloat(rightEyePosition.x), y: CGFloat(-rightEyePosition.y))
            faceNode.addChild(rightEyeNode)

            return faceNode
        } else {
            // if it is not a face: add a label node on the anchor
            let labelNode = SKLabelNode(text: "🤖")
            labelNode.horizontalAlignmentMode = .center
            labelNode.verticalAlignmentMode = .center
            return labelNode
        }
    }

    func view(_: ARSKView, didUpdate node: SKNode, for anchor: ARAnchor) {
        // This method is called when a new node has been mapped to the given anchor.
        if let faceAnchor = anchor as? ARFaceAnchor {
            // Update the node for the face anchor
            if let faceNode = node as? SKShapeNode {
                let eyeNode = faceNode.children[0] as! SKLabelNode
                let leftEyePosition = faceAnchor.leftEyeTransform.columns.3
                eyeNode.position = CGPoint(x: CGFloat(leftEyePosition.x), y: CGFloat(-leftEyePosition.y))

                let rightEyeNode = faceNode.children[1] as! SKLabelNode
                let rightEyePosition = faceAnchor.rightEyeTransform.columns.3
                rightEyeNode.position = CGPoint(x: CGFloat(rightEyePosition.x), y: CGFloat(-rightEyePosition.y))
            }
        }
    }

    func session(_: ARSession, didFailWithError _: Error) {
        // Present an error message to the user
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
