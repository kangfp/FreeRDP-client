import Foundation

/// 定位本机安装的 FreeRDP 客户端可执行文件。
public enum FreeRDPBinary {

    public static let searchDirectories = [
        "/opt/homebrew/bin",
        "/usr/local/bin",
        "/opt/local/bin",
        "/usr/bin",
    ]

    public static func find(named name: String) -> URL? {
        let fm = FileManager.default
        for dir in searchDirectories {
            let url = URL(fileURLWithPath: dir).appendingPathComponent(name)
            if fm.isExecutableFile(atPath: url.path) { return url }
        }
        // 再扫一遍 PATH
        if let path = ProcessInfo.processInfo.environment["PATH"] {
            for dir in path.split(separator: ":") {
                let url = URL(fileURLWithPath: String(dir)).appendingPathComponent(name)
                if fm.isExecutableFile(atPath: url.path) { return url }
            }
        }
        return nil
    }

    public static var sdl: URL? { find(named: "sdl-freerdp") }
    public static var xfreerdp: URL? { find(named: "xfreerdp") }

    /// 按配置选择客户端；找不到返回 nil。
    public static func resolve(for profile: ConnectionProfile) -> URL? {
        switch profile.binaryKind {
        case .auto: return sdl ?? xfreerdp
        case .sdl: return sdl
        case .xfreerdp: return xfreerdp
        case .custom:
            let p = profile.customBinaryPath
            guard !p.isEmpty else { return nil }
            return FileManager.default.isExecutableFile(atPath: p) ? URL(fileURLWithPath: p) : nil
        }
    }

    public static func versionString(of url: URL) -> String? {
        let proc = Process()
        proc.executableURL = url
        proc.arguments = ["/version"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        do {
            try proc.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            proc.waitUntilExit()
            return String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }
}
