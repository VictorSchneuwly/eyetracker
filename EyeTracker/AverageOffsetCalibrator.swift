//
//  AverageOffsetCalibrator.swift
//  EyeTracker
//
//  Created by Victor Schneuwly on 12.05.2024.
//
import ARKit
import SceneKit
import SpriteKit
import UIKit

class AverageOffsetCalibrator: Calibrator {
    private let averageOffset: CGPoint

    init(calibrationData: [CalibrationData]) {
        let offsetSum = calibrationData.reduce(CGPoint.zero) { result, data in
            let offset = CGPoint(x: data.gazePoint.x - data.targetPoint.x, y: data.gazePoint.y - data.targetPoint.y)
            return CGPoint(x: result.x + offset.x, y: result.y + offset.y)
        }

        averageOffset = offsetSum / CGFloat(calibrationData.count)
    }

    func calibrate(_ point: CGPoint) -> CGPoint {
        // Applying the average offset to the provided point
        return point - averageOffset
    }
}
