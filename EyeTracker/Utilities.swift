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
