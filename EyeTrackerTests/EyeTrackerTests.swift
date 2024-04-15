//
//  EyeTrackerTests.swift
//  EyeTrackerTests
//
//  Created by Victor Schneuwly on 04.03.2024.
//

import ARKit
@testable import EyeTracker
import SceneKit
import SpriteKit
import UIKit
import XCTest

final class EyeTrackerTests: XCTestCase {
    // MARK: Test intersection

    func testIntersectionWhenLookingAtCamera() {
        let eyeTracker = AREyeTracker()
        let eyePosition = simd_float3(0, 0, 0)
        let eyeDirection = simd_float3(0, 0, -1)
        let intersection = eyeTracker.intersectionWithPlane(eyePosition: eyePosition, eyeDirection: eyeDirection)
        XCTAssertEqual(intersection, simd_float3(0, 0, 0))
    }

    func testIntersectionWithNonZeroOrigin() {
        let eyeTracker = AREyeTracker()
        let eyePosition = simd_float3(1, 1, 1) // Non-zero origin
        let eyeDirection = simd_float3(0, 0, -1) // Looking straight ahead
        let intersection = eyeTracker.intersectionWithPlane(eyePosition: eyePosition, eyeDirection: eyeDirection)
        XCTAssertEqual(intersection, simd_float3(1, 1, 0)) // Expected intersection on the z=0 plane
    }

    func testParallelEyeDirectionAndPlane() {
        let eyeTracker = AREyeTracker()
        let eyePosition = simd_float3(0, 0, 1) // Above the z=0 plane
        let eyeDirection = simd_float3(1, 0, 0) // Parallel to the z=0 plane
        let intersection = eyeTracker.intersectionWithPlane(eyePosition: eyePosition, eyeDirection: eyeDirection)
        XCTAssertNil(intersection) // Expect nil as the direction is parallel to the plane
    }

    func testPrint() {
        print("UIScreen: bounds      : \(UIScreen.main.bounds)")
        print("UIScreen: nativeBounds: \(UIScreen.main.nativeBounds)")
        print("UIScreen: scale       : \(UIScreen.main.scale)")
        print("UIScreen: nativeScale : \(UIScreen.main.nativeScale)")
        print("UIModel: \(UIDevice.current.model)")

        print("Device: \(Device.name ?? "Unknown")")
        print("PPI: \(Device.ppi ?? -1)")
    }

    // MARK: Test project

    func testProjectForPointMiddleRight() {
        // We assume we use an iPad Mini 6th

        let width = 0.1954
        let heigh = 0.1348

        let topLeft = SCNVector3(width, 0, 0)
        let screenSize = UIScreen.main.bounds
        let size = CGSize(width: screenSize.width, height: screenSize.height)
        let screen = AREyeTracker.Screen(size: size)

        let eyeTracker = AREyeTracker()
        let projection = eyeTracker.project(point: topLeft, on: screen)
        let expected = CGPoint(
            x: screen.size.width,
            y: screen.size.height / 2
        )

        XCTAssertEqual(projection, expected)
    }
}
