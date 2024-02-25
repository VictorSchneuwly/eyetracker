//
//  Scene.swift
//  FaceTracker
//
//  Created by Victor Schneuwly on 25.02.2024.
//

import ARKit
import SpriteKit

class Scene: SKScene {
    override func didMove(to _: SKView) {
        // Setup your scene here
    }

    override func update(_: TimeInterval) {
        // Called before each frame is rendered
    }

    override func touchesBegan(_: Set<UITouch>, with _: UIEvent?) {
        guard let sceneView = view as? ARSKView else {
            return
        }

        // Create anchor using the camera's current position
        if let currentFrame = sceneView.session.currentFrame {
            // Create a transform with a translation of 0.2 meters in front of the camera
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -0.2
            let transform = simd_mul(currentFrame.camera.transform, translation)

            // Add a new anchor to the session
            let anchor = ARAnchor(transform: transform)
            sceneView.session.add(anchor: anchor)
        }
    }
}
