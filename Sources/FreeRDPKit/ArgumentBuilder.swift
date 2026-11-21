import Foundation

/// 把连接配置翻译成 FreeRDP 3 命令行参数。
/// 实际启动时通过 `/args-from:stdin` 逐行传入，密码不会出现在进程列表里。
public enum ArgumentBuilder {

    public static func build(profile p: ConnectionProfile,
                             password: String?,
                             gatewayPassword: String?) -> [String] {
        var a: [String] = []

        // ---- 连接 ----
        a.append("/v:\(p.host)")
        a.append("/port:\(p.port)")
        if !p.username.isEmpty { a.append("/u:\(p.username)") }
        if !p.domain.isEmpty { a.append("/d:\(p.domain)") }
        if let pw = password, !pw.isEmpty { a.append("/p:\(pw)") }
        a.append("/t:\(p.effectiveTitle)")
        if p.adminSession { a.append("+admin") }
        a.append(p.autoReconnect ? "+auto-reconnect" : "-auto-reconnect")
        if p.autoReconnect { a.append("/auto-reconnect-max-retries:\(p.autoReconnectMaxRetries)") }

        // ---- 网关 ----
        if p.gatewayEnabled && !p.gatewayHost.isEmpty {
            var parts = ["g:\(p.gatewayHost)\(p.gatewayPort == 443 ? "" : ":\(p.gatewayPort)")"]
            if !p.gatewayUsername.isEmpty { parts.append("u:\(p.gatewayUsername)") }
            if !p.gatewayDomain.isEmpty { parts.append("d:\(p.gatewayDomain)") }
            if let gpw = gatewayPassword, !gpw.isEmpty { parts.append("p:\(gpw)") }
            parts.append("type:\(p.gatewayType)")
            a.append("/gateway:" + parts.joined(separator: ","))
        }

        // ---- 显示 ----
        switch p.resolutionMode {
        case .fullscreen:
            a.append("+f")
        case .window:
            a.append("/w:\(p.width)")
            a.append("/h:\(p.height)")
        case .percent:
            a.append("/size:\(p.percent)%")
        }
        if p.dynamicResolution && p.resolutionMode != .fullscreen { a.append("+dynamic-resolution") }
        if p.workarea { a.append("+workarea") }
        if p.multimon { a.append("+multimon") }
        if p.span { a.append("+span") }
        a.append("/bpp:\(p.bpp)")
        if p.scale != 100 { a.append("/scale:\(p.scale)") }
        if p.scaleDesktop != 100 { a.append("/scale-desktop:\(p.scaleDesktop)") }
        if p.smartSizing { a.append("+smart-sizing") }
        if p.floatbar { a.append("/floatbar") }

        // ---- 性能 ----
        a.append("/network:\(p.network.rawValue)")
        switch p.gfxMode {
        case .auto: a.append("/gfx")
        case .progressive: a.append("/gfx:progressive:on")
        case .avc420: a.append("/gfx:AVC420:on")
        case .avc444: a.append("/gfx:AVC444:on")
        case .rfx: a.append("/gfx:RFX:on")
        case .off: a.append("-gfx")
        }
        if !p.compression { a.append("-compression") }
        if p.jpeg {
            a.append("+jpeg")
            a.append("/jpeg-quality:\(p.jpegQuality)")
        }
        if p.wallpaper { a.append("+wallpaper") }
        if !p.fontSmoothing { a.append("-fonts") }
        if !p.themes { a.append("-themes") }
        if p.menuAnims { a.append("+menu-anims") }
        if p.windowDrag { a.append("+window-drag") }
        if p.aero { a.append("+aero") }

        // ---- 本地资源 ----
        if !p.clipboard {
            a.append("-clipboard")
        } else {
            var parts: [String] = []
            if p.clipboardDirection != .all { parts.append("direction-to:\(p.clipboardDirection.rawValue)") }
            if !p.clipboardFiles { parts.append("files-to:off") }
            if !parts.isEmpty { a.append("/clipboard:" + parts.joined(separator: ",")) }
        }
        for drive in p.drives where !drive.path.isEmpty {
            let name = drive.name.isEmpty ? "share" : drive.name
            a.append("/drive:\(name),\(drive.path)")
        }
        if p.homeDrive { a.append("+home-drive") }
        if p.allDrives { a.append("+drives") }
        switch p.soundMode {
        case .redirect: a.append("/sound")
        case .remote: a.append("/audio-mode:1")
        case .none: a.append("/audio-mode:2")
        }
        if p.microphone { a.append("/microphone") }
        if p.printer { a.append("/printer") }
        if p.smartcard { a.append("/smartcard") }
        if p.usbAuto { a.append("/usb:auto") }
        var kbdParts: [String] = []
        if !p.keyboardLayout.isEmpty { kbdParts.append("layout:\(p.keyboardLayout)") }
        kbdParts.append("unicode:\(p.keyboardUnicode ? "on" : "off")")
        a.append("/kbd:" + kbdParts.joined(separator: ","))
        if !p.grabKeyboard { a.append("-grab-keyboard") }
        if !p.timezone.isEmpty { a.append("/timezone:\(p.timezone)") }

        // ---- 安全 ----
        if p.securityProtocol != .auto { a.append("/sec:\(p.securityProtocol.rawValue)") }
        a.append("/cert:\(p.certPolicy.rawValue)")
        var tlsParts: [String] = []
        if p.tlsSeclevel >= 0 { tlsParts.append("seclevel:\(p.tlsSeclevel)") }
        if !p.tlsEnforce.isEmpty { tlsParts.append("enforce:\(p.tlsEnforce)") }
        if !tlsParts.isEmpty { a.append("/tls:" + tlsParts.joined(separator: ",")) }
        if p.restrictedAdmin { a.append("+restricted-admin") }

        // ---- 高级 ----
        if p.timeoutMs > 0 { a.append("/timeout:\(p.timeoutMs)") }
        if p.preventSessionLock { a.append("+prevent-session-lock") }
        if !p.multitransport { a.append("-multitransport") }
        a.append("/log-level:\(p.logLevel.rawValue)")

        // 额外参数: 每行一个, 忽略空行和 # 注释
        for line in p.extraArgs.split(separator: "\n", omittingEmptySubsequences: false) {
            let t = line.trimmingCharacters(in: .whitespaces)
            if !t.isEmpty && !t.hasPrefix("#") { a.append(t) }
        }

        return a
    }

    /// 用于界面预览: 密码打码
    public static func preview(profile: ConnectionProfile,
                               password: String?,
                               gatewayPassword: String?) -> [String] {
        let masked = (password?.isEmpty == false) ? "••••••••" : nil
        let maskedGW = (gatewayPassword?.isEmpty == false) ? "••••••••" : nil
        return build(profile: profile, password: masked, gatewayPassword: maskedGW)
    }
}
