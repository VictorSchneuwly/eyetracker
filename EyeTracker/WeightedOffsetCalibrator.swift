//
//  WeightedOffsetCalibrator.swift
//  EyeTracker
//
//  Created by Victor Schneuwly on 12.05.2024.
//
import ARKit
import SceneKit
import SpriteKit
import UIKit

class WeightedOffsetCalibrator: Calibrator {
    private let averageOffset: CGPoint

    init(calibrationData: [CalibrationData]) {
        var weightedSum = CGPoint.zero
        var totalWeight = 0.0

        // Weight by how much the face is looking straight
        for data in calibrationData {
            let faceForwardness = max(
                0.0,
                simd_dot(
                    simd_float3(
                        data.faceTransform.columns.2.x,
                        data.faceTransform.columns.2.y,
                        data.faceTransform.columns.2.z
                    ),
                    simd_float3(0, 0, 1)
                )
            )
            let weight = Double(faceForwardness)

            let offset = CGPoint(x: data.gazePoint.x - data.targetPoint.x, y: data.gazePoint.y - data.targetPoint.y)
            weightedSum.x += offset.x * CGFloat(weight)
            weightedSum.y += offset.y * CGFloat(weight)
            totalWeight += weight
        }

        averageOffset = weightedSum / CGFloat(totalWeight)
    }

    func calibrate(_ point: CGPoint) -> CGPoint {
        // Applying the average offset to the provided point
        return point - averageOffset
    }
}
