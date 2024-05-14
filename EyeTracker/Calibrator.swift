//
//  Calibrator.swift
//  EyeTracker
//
//  Created by Victor Schneuwly on 12.05.2024.
//

import ARKit
import SceneKit
import SpriteKit
import UIKit

protocol Calibrator {
    func calibrate(_ point: CGPoint) -> CGPoint
}
