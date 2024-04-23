//
//  CalibrationScene.swift
//  EyeTracker
//
//  Created by Victor Schneuwly on 22.04.2024.
//

import SpriteKit
import UIKit

class CalibrationScene: SKScene {
    var calibrationDelegate: CalibrationDelegate?

    private let target = SKShapeNode(circleOfRadius: 25)
    private let nextButton = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 100, height: 50))

    private var calibrationPoints: [CGPoint] = []
    private var currentPointIndex = 0

    private var calibrationData: [CalibrationData] = []

    override func sceneDidLoad() {
        // Setup ui
        target.name = "target"
        target.fillColor = .red
        target.strokeColor = .red

        nextButton.name = "next"
        nextButton.fillColor = .blue
        nextButton.strokeColor = .blue

        // Add the points to the list
        calibrationPoints = createCalibrationPoints()
    }

    func startCalibration() {
        isUserInteractionEnabled = true
        showUI()
    }

    func stopCalibration() {
        isUserInteractionEnabled = false
        removeAllChildren()
    }

    private func showUI() {
        // Setup target
        target.position = calibrationPoints[currentPointIndex]
        addChild(target)

        // Setup next button
        nextButton.position = CGPoint(x: size.width / 2, y: 50)
        addChild(nextButton)
    }

    private func createCalibrationPoints() -> [CGPoint] {
        let possibleXs = [0, size.width / 2, size.width]
        let possibleYs = [0, size.height / 2, size.height]
        return possibleYs.flatMap { pty in
            possibleXs.map { ptx in
                CGPoint(x: ptx, y: pty)
            }
        }
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
        // Only activate when the next button is pressed
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = nodes(at: location)
        guard nodes.contains(nextButton) else { return }

        // Store the calibration data
        if let calibrationDelegate = calibrationDelegate {
            let calibrationData = calibrationDelegate.getCalibrationData(for: target.position)
            self.calibrationData.append(calibrationData)
        }

        // Update the target position
        currentPointIndex += 1
        currentPointIndex %= calibrationPoints.count
        target.position = calibrationPoints[currentPointIndex]
    }
}

// MARK: - Calibration Data

struct CalibrationData {
    let targetPoint: CGPoint
    let gazePoint: CGPoint
    let faceTransform: simd_float4x4
    let rightEyeTransform: simd_float4x4
    let leftEyeTransform: simd_float4x4
}

// MARK: - Calibration Delegate

protocol CalibrationDelegate: AnyObject {
    func startCalibration()
    func stopCalibration()
    func getCalibrationData(for target: CGPoint) -> CalibrationData?
}
