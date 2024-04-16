//
//  AREyeTracker.swift
//  EyeTracker
//
//  Created by Victor Schneuwly on 26.03.2024.
//

import ARKit
import SceneKit
import SpriteKit
import UIKit

class AREyeTracker {
    /**
     Calculates the intersection of the eye direction with the z=0 plane
     - Parameters:
     - eyePosition: The position of the eye in the camera space
     - eyeDirection: The direction the eye is looking at in the camera space
     - Returns: The intersection point of the eye direction with the z=0 plane
     */
    func intersectionWithPlane(eyePosition: simd_float3, eyeDirection: simd_float3) -> simd_float3? {
        if eyeDirection.z == 0 {
            // If the eye is looking parallel to the z=0 plane, there is no intersection
            print("Eye is looking parallel to the z=0 plane")
            return nil
        }

        let dir = -eyePosition.z / eyeDirection.z

        return eyePosition + dir * eyeDirection
    }

    /**
     Projects a 3D point onto a 2D screen
     - Parameters:
     - point: The 3D point to project in global coordinates
     - screen: The screen to project the point on
     - Returns: The 2D point on the screen
     */
    func project(point: SCNVector3) -> CGPoint {
        // We can discard the z coordinate of the point
        // We know the camera is at x = 0 and y = screen.size.width / 2
        // The point coordinates are given in meters with the camera as origin
        // We have access to the ppi and a function from inch to meters

        guard let tmp = Device.ppi else {
            fatalError("Device PPI is not set")
        }

        let ppi = CGFloat(tmp)

        let pointInPixel = CGPoint(
            x: metersToInches(CGFloat(point.x)) * ppi,
            y: metersToInches(CGFloat(point.y)) * ppi
        )

        // We have to turn the coordinate from pixel to points
        let pointInScreenCoordinates = pointInPixel / UIScreen.main.scale

        // finally, since the point is relative to the camera
        // and that the camera is at the center of the screen
        // we have to shift the point y coordinate
        return CGPoint(
            x: pointInScreenCoordinates.x,
            y: pointInScreenCoordinates.y + UIScreen.main.bounds.height / 2
        )
    }

    /**
     Gets the look point on the screen
     - Parameters:
     - screen: The screen to get the look point on
     - faceAnchor: The face anchor to get the eye position and direction from
     - Returns: The look point on the screen
     */
    func getLookOnScreen(using faceAnchor: ARFaceAnchor) -> CGPoint? {
        // let cameraTransform = screen.camera.transform

        let eyeCameraPosition =
            simd_make_float3(faceAnchor.rightEyeTransform.columns.3).toWorldCoordinate(using: faceAnchor.transform)

        // Forward direction in world space - assuming the eye is looking along the negative Z-axis
        let eyeCameraDirection =
            simd_make_float3(faceAnchor.rightEyeTransform.columns.2).toWorldCoordinate(using: faceAnchor.transform)

        guard let intersection = intersectionWithPlane(
            eyePosition: eyeCameraPosition, eyeDirection: eyeCameraDirection
        ) else {
            print("No intersection")
            return nil
        }

        return project(point: SCNVector3(intersection))
    }
}
