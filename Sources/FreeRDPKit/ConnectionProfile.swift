import Foundation

// MARK: - 枚举选项

public enum ResolutionMode: String, Codable, CaseIterable, Identifiable {
    case fullscreen, window, percent
    public var id: String { rawValue }
    public var label: String {
        switch self {
        case .fullscreen: return "全屏"
        case .window: return "指定分辨率"
        case .percent: return "屏幕百分比"
        }
    }
}

public enum NetworkType: String, Codable, CaseIterable, Identifiable {
    case auto, lan, wan, broadbandHigh = "broadband-high", broadbandLow = "broadband-low", modem
    public var id: String { rawValue }
    public var label: String {
        switch self {
        case .auto: return "自动检测"
        case .lan: return "局域网 (LAN)"
        case .wan: return "广域网 (WAN)"
        case .broadbandHigh: return "高速宽带"
        case .broadbandLow: return "低速宽带"
        case .modem: return "调制解调器 (慢速)"
        }
    }
}

public enum GfxMode: String, Codable, CaseIterable, Identifiable {
    case auto, progressive, avc420, avc444, rfx, off
    public var id: String { rawValue }
    public var label: String {
        switch self {
        case .auto: return "自动 (RDP8 图形管线)"
        case .progressive: return "Progressive (渐进式)"
        case .avc420: return "H.264 AVC420"
        case .avc444: return "H.264 AVC444 (文字更清晰)"
        case .rfx: return "RemoteFX"
        case .off: return "关闭图形管线"
        }
    }
}

public enum SoundMode: String, Codable, CaseIterable, Identifiable {
    case redirect, remote, none
    public var id: String { rawValue }
    public var label: String {
        switch self {
        case .redirect: return "重定向到本机播放"
        case .remote: return "在远程计算机播放"
        case .none: return "静音"
        }
    }
}

public enum ClipboardDirection: String, Codable, CaseIterable, Identifiable {
    case all, local, remote, off
    public var id: String { rawValue }
    public var label: String {
        switch self {
        case .all: return "双向"
        case .local: return "仅远程 → 本机"
        case .remote: return "仅本机 → 远程"
        case .off: return "关闭"
        }
    }
}

public enum SecurityProtocol: String, Codable, CaseIterable, Identifiable {
    case auto, nla, tls, rdp, ext, aad
    public var id: String { rawValue }
    public var label: String {
        switch self {
        case .auto: return "自动协商 (推荐)"
        case .nla: return "强制 NLA (网络级认证)"
        case .tls: return "强制 TLS"
        case .rdp: return "旧式 RDP 加密 (不推荐)"
        case .ext: return "Ext (NLA 扩展)"
        case .aad: return "Azure AD"
        }
    }
}

public enum CertPolicy: String, Codable, CaseIterable, Identifiable {
    case tofu, ignore, deny
    public var id: String { rawValue }
    public var label: String {
        switch self {
        case .tofu: return "首次信任 (TOFU, 推荐)"
        case .ignore: return "忽略证书校验 (仅限可信内网)"
        case .deny: return "严格校验, 不匹配即断开"
        }
    }
}

public enum ClientBinaryKind: String, Codable, CaseIterable, Identifiable {
    case auto, sdl, xfreerdp, custom
    public var id: String { rawValue }
    public var label: String {
        switch self {
        case .auto: return "自动 (优先 sdl-freerdp)"
        case .sdl: return "sdl-freerdp (原生, 推荐)"
        case .xfreerdp: return "xfreerdp (需要 XQuartz)"
        case .custom: return "自定义路径…"
        }
    }
}

public enum LogLevel: String, Codable, CaseIterable, Identifiable {
    case off = "OFF", fatal = "FATAL", error = "ERROR", warn = "WARN", info = "INFO", debug = "DEBUG", trace = "TRACE"
    public var id: String { rawValue }
}

// MARK: - 驱动器重定向

public struct DriveRedirect: Codable, Identifiable, Equatable {
    public var id = UUID()
    public var name: String
    public var path: String
    public init(name: String, path: String) {
        self.name = name
        self.path = path
    }
}

// MARK: - 连接配置

public struct ConnectionProfile: Codable, Identifiable, Equatable {
    public var id = UUID()
    public var name: String = "新建连接"

    // 连接
    public var host: String = ""
    public var port: Int = 3389
    public var username: String = ""
    public var domain: String = ""
    public var windowTitle: String = ""
    public var adminSession: Bool = false
    public var autoReconnect: Bool = true
    public var autoReconnectMaxRetries: Int = 20

    // 网关
    public var gatewayEnabled: Bool = false
    public var gatewayHost: String = ""
    public var gatewayPort: Int = 443
    public var gatewayUsername: String = ""
    public var gatewayDomain: String = ""
    public var gatewayType: String = "auto"   // auto | rpc | http

    // 显示
    public var resolutionMode: ResolutionMode = .window
    public var width: Int = 1920
    public var height: Int = 1080
    public var percent: Int = 80
    public var dynamicResolution: Bool = true
    public var workarea: Bool = false
    public var multimon: Bool = false
    public var span: Bool = false
    public var bpp: Int = 32
    public var scale: Int = 100               // 100 | 140 | 180
    public var scaleDesktop: Int = 100        // 100...500, 100 = 不缩放
    public var smartSizing: Bool = false
    public var floatbar: Bool = true

    // 性能
    public var network: NetworkType = .auto
    public var gfxMode: GfxMode = .auto
    public var compression: Bool = true
    public var jpeg: Bool = false
    public var jpegQuality: Int = 75
    public var wallpaper: Bool = false
    public var fontSmoothing: Bool = true
    public var themes: Bool = true
    public var menuAnims: Bool = false
    public var windowDrag: Bool = false
    public var aero: Bool = false

    // 本地资源
    public var clipboard: Bool = true
    public var clipboardDirection: ClipboardDirection = .all
    public var clipboardFiles: Bool = true
    public var drives: [DriveRedirect] = []
    public var homeDrive: Bool = false
    public var allDrives: Bool = false
    public var soundMode: SoundMode = .redirect
    public var microphone: Bool = false
    public var printer: Bool = false
    public var smartcard: Bool = false
    public var usbAuto: Bool = false
    public var keyboardLayout: String = ""    // 如 0x00000804 或名称, 留空自动
    public var keyboardUnicode: Bool = true
    public var grabKeyboard: Bool = true
    public var timezone: String = ""          // Windows 时区名, 留空不发送

    // 安全
    public var securityProtocol: SecurityProtocol = .auto
    public var certPolicy: CertPolicy = .tofu
    public var tlsSeclevel: Int = -1          // -1 = 默认, 0...5
    public var tlsEnforce: String = ""        // "" | 1.0 | 1.1 | 1.2 | 1.3
    public var restrictedAdmin: Bool = false

    // 高级
    public var binaryKind: ClientBinaryKind = .auto
    public var customBinaryPath: String = ""
    public var logLevel: LogLevel = .info
    public var timeoutMs: Int = 0             // 0 = 默认
    public var preventSessionLock: Bool = false
    public var multitransport: Bool = true
    public var extraArgs: String = ""         // 每行一个参数

    public init() {}

    public var effectiveTitle: String {
        windowTitle.isEmpty ? name : windowTitle
    }
}
