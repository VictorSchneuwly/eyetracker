//
//  Utilities.swift
//  EyeTracker
//
//  Created by Victor Schneuwly on 05.03.2024.
//

import ARKit

extension simd_float3 {
    func toWorldCoordinate(using transform: simd_float4x4) -> simd_float3 {
        return changeCooringateSystem(to: transform)
    }

    func toLocalCoordinate(using transform: simd_float4x4) -> simd_float3 {
        return changeCooringateSystem(to: transform.inverse)
    }

    private func changeCooringateSystem(to tranform: simd_float4x4) -> simd_float3 {
        let tmp = simd_mul(tranform, simd_make_float4(self, 1))
        return simd_make_float3(tmp.x, tmp.y, tmp.z)
    }
}

extension CGFloat {
    func clamped(to limits: ClosedRange<CGFloat>) -> CGFloat {
        return Swift.min(Swift.max(self, limits.lowerBound), limits.upperBound)
    }
}

func createLineNode(from startPoint: simd_float3, to endPoint: simd_float3) -> SCNNode {
    let lineRadius: CGFloat = 0.002 // Thin line
    // Update the cylinder's height to match the distance between the start and end points
    let distance = simd_distance(startPoint, endPoint)
    let lineGeometry = SCNCylinder(radius: lineRadius, height: CGFloat(distance))
    lineGeometry.firstMaterial?.diffuse.contents = UIColor.red // Line color
    let lineNode = SCNNode(geometry: lineGeometry)
    lineNode.name = "line"

    // Calculate the midpoint
    let midPoint = (startPoint + endPoint) / 2.0
    lineNode.position = SCNVector3(midPoint.x, midPoint.y, midPoint.z)

    // Calculate the orientation of the line
    let w = endPoint - startPoint
    let wLength = simd_length(w)
    let up = simd_float3(0, 1, 0)
    let axis = simd_cross(up, w)
    let angle = acos(simd_dot(up, w) / wLength)

    // Apply the rotation to align the cylinder with the line direction
    lineNode.rotation = SCNVector4(axis.x, axis.y, axis.z, angle)

    return lineNode
}

func updateLineNode(from startPoint: simd_float3, to endPoint: simd_float3, on sceneView: ARSCNView) {
    guard let lineNode = sceneView.scene.rootNode.childNode(withName: "line", recursively: true) else {
        return
    }

    // Calculate the midpoint
    let midPoint = (startPoint + endPoint) / 2.0
    lineNode.position = SCNVector3(midPoint.x, midPoint.y, midPoint.z)

    // Update the cylinder's height to match the distance between the start and end points
    let distance = simd_distance(startPoint, endPoint)
    guard let geometry = lineNode.geometry as? SCNCylinder else {
        fatalError("The geometry of the line node is not a cylinder")
    }
    geometry.height = CGFloat(distance)

    // Calculate the orientation of the line
    let w = endPoint - startPoint
    let wLength = simd_length(w)
    let up = simd_float3(0, 1, 0)
    let axis = simd_cross(up, w)
    let angle = acos(simd_dot(up, w) / wLength)

    // Apply the rotation to align the cylinder with the line direction
    lineNode.rotation = SCNVector4(axis.x, axis.y, axis.z, angle)
}