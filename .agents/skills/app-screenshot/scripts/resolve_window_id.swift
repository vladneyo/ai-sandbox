import CoreGraphics
import Darwin
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 3, arguments[1] == "--pid", let pid = Int32(arguments[2]) else {
    fputs("usage: resolve_window_id.swift --pid PID\n", stderr)
    exit(2)
}

let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
    exit(1)
}

func integerValue(_ value: Any?) -> Int? {
    if let value = value as? Int {
        return value
    }
    if let value = value as? Int32 {
        return Int(value)
    }
    if let value = value as? UInt32 {
        return Int(value)
    }
    if let value = value as? NSNumber {
        return value.intValue
    }
    return nil
}

// CGWindowListCopyWindowInfo returns windows front-to-back. Select the first
// normal-layer window owned by the target process, which is the app's visible
// front window in the common single-window application case. Retain a non-normal
// layer as a fallback because some native window managers assign a transient
// layer while the app is settling.
var fallbackWindow: Int?

for info in windowList {
    let ownerPID = integerValue(info[kCGWindowOwnerPID as String])
    let layer = integerValue(info[kCGWindowLayer as String])
    let windowNumber = integerValue(info[kCGWindowNumber as String])

    guard ownerPID == Int(pid), let windowNumber, windowNumber > 0 else {
        continue
    }

    if layer == 0 {
        print(windowNumber)
        exit(0)
    }
    if fallbackWindow == nil {
        fallbackWindow = windowNumber
    }
}

if let fallbackWindow {
    print(fallbackWindow)
    exit(0)
}
exit(1)
