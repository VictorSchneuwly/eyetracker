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
    private let border = 0.009
    private let realWidth = 0.1954 - 0.018
    private let realHeight = 0.1348 - 0.018

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

        let middleRight = SCNVector3(realWidth, 0, 0)

        let eyeTracker = AREyeTracker()
        let projection = eyeTracker.project(point: middleRight)
        let expected = CGPoint(
            x: UIScreen.main.bounds.width,
            y: UIScreen.main.bounds.height / 2
        )

        XCTAssertEqual(projection, expected)
    }

    func testProjectForPointMiddleLeft() {
        // We assume we use an iPad Mini 6th
        let middleLeft = SCNVector3(0, 0, 0)

        let eyeTracker = AREyeTracker()
        let projection = eyeTracker.project(point: middleLeft)
        let expected = CGPoint(
            x: 0,
            y: UIScreen.main.bounds.height / 2
        )
        XCTAssertEqual(projection, expected)
    }

    func testProjectForPointBottomLeft() {
        // We assume we use an iPad Mini 6th

        let bottomLeft = SCNVector3(0, -realHeight / 2, 0)

        let eyeTracker = AREyeTracker()
        let projection = eyeTracker.project(point: bottomLeft)
        let expected = CGPoint(x: 0, y: 0)

        XCTAssertEqual(projection, expected)
    }

    func testProjectForMiddleOfScreen() {
        // We assume we use an iPad Mini 6th
        let middle = SCNVector3(realWidth / 2, 0, 0)

        let eyeTracker = AREyeTracker()
        let projection = eyeTracker.project(point: middle)
        let expected = CGPoint(
            x: UIScreen.main.bounds.width / 2,
            y: UIScreen.main.bounds.height / 2
        )
        XCTAssertEqual(projection, expected)
    }

    func testProjectForPointMiddleTop() {
        // We assume we use an iPad Mini 6th
        let middleTop = SCNVector3(realWidth / 2, realHeight / 2, 0)
        let eyeTracker = AREyeTracker()
        let projection = eyeTracker.project(point: middleTop)
        let expected = CGPoint(
            x: UIScreen.main.bounds.width / 2,
            y: UIScreen.main.bounds.height
        )
        XCTAssertEqual(projection, expected)
    }
}
