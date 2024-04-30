//
//  CalibrationUtils.swift
//  EyeTracker
//
//  Created by Victor Schneuwly on 28.04.2024.
//

import ARKit

enum CalibrationState {
    case base
    case calibration(CGPoint, HeadPosition, PositionToScreen)
    case done
}

enum HeadPosition: String, CaseIterable {
    case middle = "Middle"
    case top = "Top"
    case down = "Down"
    case left = "Left"
    case right = "Right"

    func next() -> HeadPosition {
        let allCases = HeadPosition.allCases
        let currentIndex = allCases.firstIndex(of: self)!
        return allCases[(currentIndex + 1) % allCases.count]
    }

    func instruction() -> String {
        switch self {
        case .middle:
            return "Face the middle of the screen while looking at the target."
        case .top:
            return "Move your head up while looking at the target."
        case .down:
            return "Move your head down while looking at the target."
        case .left:
            return "Move your head to the left while looking at the target."
        case .right:
            return "Move your head to the right while looking at the target."
        }
    }
}

enum PositionToScreen: String, CaseIterable {
    case regular = "Regular"
    case armsExtended = "Arms Extended"
    case close = "Close"

    func next() -> PositionToScreen {
        let allCases = PositionToScreen.allCases
        let currentIndex = allCases.firstIndex(of: self)!
        return allCases[(currentIndex + 1) % allCases.count]
    }

    func instruction() -> String {
        switch self {
        case .regular:
            return "Hold your device at a regular distance from your face."
        case .armsExtended:
            return "Hold your device at arms extended distance from your face."
        case .close:
            return "Hold your device close to your face."
        }
    }
}

// MARK: - Calibration Data

struct CalibrationData {
    let username: String
    let deviceName: String
    let position: HeadPosition
    let distance: PositionToScreen
    let timestamp: Date
    let targetPoint: CGPoint
    let gazePoint: CGPoint
    let faceTransform: simd_float4x4
    let rightEyeTransform: simd_float4x4
    let leftEyeTransform: simd_float4x4
    let lookAtPoint: simd_float3

    static let csvHeader =
        "username, deviceName, position, distance, timestamp,"
            + "targetPointX, targetPointY, gazePointX, gazePointY,"
            + "faceTransform_0_x, faceTransform_0_y, faceTransform_0_z, faceTransform_0_w,"
            + "faceTransform_1_x, faceTransform_1_y, faceTransform_1_z, faceTransform_1_w,"
            + "faceTransform_2_x, faceTransform_2_y, faceTransform_2_z, faceTransform_2_w,"
            + "faceTransform_3_x, faceTransform_3_y, faceTransform_3_z, faceTransform_3_w,"
            + "rightEyeTransform_0_x, rightEyeTransform_0_y, rightEyeTransform_0_z, rightEyeTransform_0_w,"
            + "rightEyeTransform_1_x, rightEyeTransform_1_y, rightEyeTransform_1_z, rightEyeTransform_1_w,"
            + "rightEyeTransform_2_x, rightEyeTransform_2_y, rightEyeTransform_2_z, rightEyeTransform_2_w,"
            + "rightEyeTransform_3_x, rightEyeTransform_3_y, rightEyeTransform_3_z, rightEyeTransform_3_w,"
            + "leftEyeTransform_0_x, leftEyeTransform_0_y, leftEyeTransform_0_z, leftEyeTransform_0_w,"
            + "leftEyeTransform_1_x, leftEyeTransform_1_y, leftEyeTransform_1_z, leftEyeTransform_1_w,"
            + "leftEyeTransform_2_x, leftEyeTransform_2_y, leftEyeTransform_2_z, leftEyeTransform_2_w,"
            + "leftEyeTransform_3_x, leftEyeTransform_3_y, leftEyeTransform_3_z, leftEyeTransform_3_w"
            + "lookAtPointX, lookAtPointY, lookAtPointZ"

    func csvRepresentation() -> String {
        func extractValues(from transform: simd_float4x4) -> [Float] {
            return [
                transform.columns.0.x, transform.columns.0.y, transform.columns.0.z, transform.columns.0.w,
                transform.columns.1.x, transform.columns.1.y, transform.columns.1.z, transform.columns.1.w,
                transform.columns.2.x, transform.columns.2.y, transform.columns.2.z, transform.columns.2.w,
                transform.columns.3.x, transform.columns.3.y, transform.columns.3.z, transform.columns.3.w,
            ]
        }

        let faceTransformValues = extractValues(from: faceTransform)
        let rightEyeTransformValues = extractValues(from: rightEyeTransform)
        let leftEyeTransformValues = extractValues(from: leftEyeTransform)

        let values = [
            username, deviceName, position.rawValue, distance.rawValue, timestamp.timeIntervalSince1970,
            targetPoint.x, targetPoint.y, gazePoint.x, gazePoint.y,
        ] + faceTransformValues + rightEyeTransformValues + leftEyeTransformValues
            + [lookAtPoint.x, lookAtPoint.y, lookAtPoint.z]

        return values.map { "\($0)" }.joined(separator: ",")
    }
}
