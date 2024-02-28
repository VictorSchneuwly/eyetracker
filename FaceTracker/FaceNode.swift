//
//  FaceNode.swift
//  FaceTracker
//
//  Created by Victor Schneuwly on 27.02.2024.
//

import ARKit
import SceneKit

class FaceNode: SCNNode {
    var node: SCNNode?
    var leftEyeNode: SCNNode?
    var rightEyeNode: SCNNode?

    required init?(coder aCoder: NSCoder) {
        super.init(coder: aCoder)
    }

    /// Initializer with all components
    /// - Parameters:
    ///   - faceNode: The node representing the face
    ///   - leftEyeNode: The node representing the left eye
    ///   - rightEyeNode: The node representing the right eye
    ///
    /// - Returns: A new instance of FaceNode with its components initialized using the provided nodes
    init(faceNode: SCNNode, leftEyeNode: SCNNode, rightEyeNode: SCNNode) {
        super.init()

        node = faceNode
        self.leftEyeNode = leftEyeNode
        self.rightEyeNode = rightEyeNode

        // check if the eyes are already children of the face
        if !node!.childNodes.contains(leftEyeNode) {
            node!.addChildNode(leftEyeNode)
        }
        if !node!.childNodes.contains(rightEyeNode) {
            node!.addChildNode(rightEyeNode)
        }
    }

    /// Convenience initializer with a URL
    /// - Parameters:
    ///   - url: The URL to load the nodes from
    ///
    /// - Returns: A new instance of FaceNode initialized using the nodes loaded from the provided URL
    convenience init(url: URL) {
        let face = SCNReferenceNode(url: url)
        let leftEye = SCNReferenceNode(url: url)
        let rightEye = SCNReferenceNode(url: url)

        guard let face = face,
              let leftEye = leftEye,
              let rightEye = rightEye
        else {
            fatalError("Failed to load the url: \(url), for all components")
        }

        self.init(faceNode: face, leftEyeNode: leftEye, rightEyeNode: rightEye)
    }

    /// Update the face node with the provided face anchor
    /// - Parameters:
    ///   - with: The face anchor to update the face node with
    func update(with faceAnchor: ARFaceAnchor) {
        // update the face
        node?.simdTransform = faceAnchor.transform

        // update the eyes
        leftEyeNode?.simdTransform = faceAnchor.leftEyeTransform
        rightEyeNode?.simdTransform = faceAnchor.rightEyeTransform
    }
}
