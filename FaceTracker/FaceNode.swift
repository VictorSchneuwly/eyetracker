//
//  FaceNode.swift
//  FaceTracker
//
//  Created by Victor Schneuwly on 27.02.2024.
//

import ARKit
import SceneKit

struct FaceNode {
    var faceNode: SCNNode
    var leftEyeNode: SCNNode
    var rightEyeNode: SCNNode

    init(faceNode: SCNNode, leftEyeNode: SCNNode, rightEyeNode: SCNNode) {
        self.faceNode = faceNode
        self.leftEyeNode = leftEyeNode
        self.rightEyeNode = rightEyeNode
    }

    init(url: URL) {
        faceNode = SCNReferenceNode(url: url)

        // create the eyes
        leftEyeNode = SCNReferenceNode(url: url)
        rightEyeNode = SCNReferenceNode(url: url)

        // add the eyes to the face
        faceNode.addChildNode(leftEyeNode)
        faceNode.addChildNode(rightEyeNode)
    }

    func update(with faceAnchor: ARFaceAnchor) {
        // update the face
        faceNode.simdTransform = faceAnchor.transform

        // update the eyes
        leftEyeNode.simdTransform = faceAnchor.leftEyeTransform
        rightEyeNode.simdTransform = faceAnchor.rightEyeTransform
    }
}
