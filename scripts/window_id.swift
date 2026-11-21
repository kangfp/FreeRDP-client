#!/usr/bin/env swift
// 等待指定进程的窗口出现并输出 CGWindowID
// 用法: swift scripts/window_id.swift <进程名或PID> [超时秒]
// 注意: 窗口归属名是本地化的 CFBundleName (如 "FreeRDP 客户端"), 用 PID 匹配最可靠
import CoreGraphics
import Foundation

let target = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "FreeRDPClient"
let targetPID = Int(target)
let timeout = CommandLine.arguments.count > 2 ? Double(CommandLine.arguments[2]) ?? 10 : 10
let deadline = Date().addingTimeInterval(timeout)

while Date() < deadline {
    if let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] {
        for win in list {
            let name = win[kCGWindowOwnerName as String] as? String ?? ""
            let pid = win[kCGWindowOwnerPID as String] as? Int ?? -1
            let matched = targetPID != nil ? pid == targetPID : name == target
            guard matched else { continue }
            guard let layer = win[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
            if let id = win[kCGWindowNumber as String] as? Int {
                print(id)
                exit(0)
            }
        }
    }
    usleep(300_000)
}
FileHandle.standardError.write(Data("未找到窗口\n".utf8))
exit(1)
