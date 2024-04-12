//
//  Device.swift
//  EyeTracker
//
//  Created by Victor Schneuwly on 09.04.2024.
//

import Foundation

enum Device {
    static let name = getDeviceName()
    static let ppi = getDevicePPI()

    // TODO: source
    private static func getDeviceID() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }

    private static func getDeviceName() -> String? {
        switch getDeviceID() {
        case "iPad14,1", "iPad14,2":
            return "iPad Mini 6th"
        default:
            return nil
        }
    }

    private static func getDevicePPI() -> Int? {
        switch getDeviceID() {
        case "iPad14,1", "iPad14,2":
            return 326
        default:
            return nil
        }
    }
}
