import XCTest
@testable import FreeRDPKit

final class ArgumentBuilderTests: XCTestCase {

    private func makeProfile() -> ConnectionProfile {
        var p = ConnectionProfile()
        p.name = "测试"
        p.host = "192.168.3.201"
        return p
    }

    func testDefaults() {
        let p = makeProfile()
        let args = ArgumentBuilder.build(profile: p, password: nil, gatewayPassword: nil)
        XCTAssertTrue(args.contains("/v:192.168.3.201"))
        XCTAssertTrue(args.contains("/port:3389"))
        XCTAssertTrue(args.contains("/w:1920"))
        XCTAssertTrue(args.contains("/h:1080"))
        XCTAssertTrue(args.contains("+dynamic-resolution"))
        XCTAssertTrue(args.contains("/bpp:32"))
        XCTAssertTrue(args.contains("/network:auto"))
        XCTAssertTrue(args.contains("/gfx"))
        XCTAssertTrue(args.contains("/sound"))
        XCTAssertTrue(args.contains("/cert:tofu"))
        XCTAssertTrue(args.contains("/log-level:INFO"))
        XCTAssertTrue(args.contains("/kbd:unicode:on"))
        XCTAssertTrue(args.contains("/t:测试"))
        XCTAssertFalse(args.contains { $0.hasPrefix("/p:") })
        XCTAssertFalse(args.contains { $0.hasPrefix("/u:") })
        XCTAssertFalse(args.contains { $0.hasPrefix("/gateway:") })
        XCTAssertFalse(args.contains { $0.hasPrefix("/sec:") })
    }

    func testCredentials() {
        var p = makeProfile()
        p.username = "kangfeipeng"
        p.domain = "WORKGROUP"
        let args = ArgumentBuilder.build(profile: p, password: "s3cret!", gatewayPassword: nil)
        XCTAssertTrue(args.contains("/u:kangfeipeng"))
        XCTAssertTrue(args.contains("/d:WORKGROUP"))
        XCTAssertTrue(args.contains("/p:s3cret!"))
    }

    func testPreviewMasksPassword() {
        var p = makeProfile()
        p.username = "u"
        let preview = ArgumentBuilder.preview(profile: p, password: "s3cret!", gatewayPassword: "gw")
        XCTAssertFalse(preview.contains("/p:s3cret!"))
        XCTAssertTrue(preview.contains("/p:••••••••"))
    }

    func testFullscreen() {
        var p = makeProfile()
        p.resolutionMode = .fullscreen
        let args = ArgumentBuilder.build(profile: p, password: nil, gatewayPassword: nil)
        XCTAssertTrue(args.contains("+f"))
        XCTAssertFalse(args.contains("/w:1920"))
        XCTAssertFalse(args.contains("+dynamic-resolution"))
    }

    func testPercentSize() {
        var p = makeProfile()
        p.resolutionMode = .percent
        p.percent = 80
        let args = ArgumentBuilder.build(profile: p, password: nil, gatewayPassword: nil)
        XCTAssertTrue(args.contains("/size:80%"))
    }

    func testGateway() {
        var p = makeProfile()
        p.gatewayEnabled = true
        p.gatewayHost = "gw.example.com"
        p.gatewayPort = 4430
        p.gatewayUsername = "gwuser"
        p.gatewayDomain = "CORP"
        p.gatewayType = "rpc"
        let args = ArgumentBuilder.build(profile: p, password: nil, gatewayPassword: "gwpw")
        XCTAssertTrue(args.contains("/gateway:g:gw.example.com:4430,u:gwuser,d:CORP,p:gwpw,type:rpc"))
    }

    func testGatewayDisabledWithoutHost() {
        var p = makeProfile()
        p.gatewayEnabled = true
        p.gatewayHost = ""
        let args = ArgumentBuilder.build(profile: p, password: nil, gatewayPassword: "x")
        XCTAssertFalse(args.contains { $0.hasPrefix("/gateway:") })
    }

    func testDrives() {
        var p = makeProfile()
        p.drives = [DriveRedirect(name: "MacShare", path: "/Users/kang/Shared")]
        p.homeDrive = true
        let args = ArgumentBuilder.build(profile: p, password: nil, gatewayPassword: nil)
        XCTAssertTrue(args.contains("/drive:MacShare,/Users/kang/Shared"))
        XCTAssertTrue(args.contains("+home-drive"))
    }

    func testClipboardDirections() {
        var p = makeProfile()
        p.clipboardDirection = .local
        p.clipboardFiles = false
        var args = ArgumentBuilder.build(profile: p, password: nil, gatewayPassword: nil)
        XCTAssertTrue(args.contains("/clipboard:direction-to:local,files-to:off"))

        p.clipboard = false
        args = ArgumentBuilder.build(profile: p, password: nil, gatewayPassword: nil)
        XCTAssertTrue(args.contains("-clipboard"))
    }

    func testSoundModes() {
        var p = makeProfile()
        p.soundMode = .none
        p.microphone = true
        let args = ArgumentBuilder.build(profile: p, password: nil, gatewayPassword: nil)
        XCTAssertTrue(args.contains("/audio-mode:2"))
        XCTAssertTrue(args.contains("/microphone"))
        XCTAssertFalse(args.contains("/sound"))
    }

    func testSecurityAndTLS() {
        var p = makeProfile()
        p.securityProtocol = .nla
        p.certPolicy = .ignore
        p.tlsSeclevel = 0
        p.tlsEnforce = "1.0"
        let args = ArgumentBuilder.build(profile: p, password: nil, gatewayPassword: nil)
        XCTAssertTrue(args.contains("/sec:nla"))
        XCTAssertTrue(args.contains("/cert:ignore"))
        XCTAssertTrue(args.contains("/tls:seclevel:0,enforce:1.0"))
    }

    func testPerformanceFlags() {
        var p = makeProfile()
        p.gfxMode = .avc444
        p.wallpaper = true
        p.fontSmoothing = false
        p.compression = false
        p.network = .modem
        let args = ArgumentBuilder.build(profile: p, password: nil, gatewayPassword: nil)
        XCTAssertTrue(args.contains("/gfx:AVC444:on"))
        XCTAssertTrue(args.contains("+wallpaper"))
        XCTAssertTrue(args.contains("-fonts"))
        XCTAssertTrue(args.contains("-compression"))
        XCTAssertTrue(args.contains("/network:modem"))
    }

    func testGfxOff() {
        var p = makeProfile()
        p.gfxMode = .off
        let args = ArgumentBuilder.build(profile: p, password: nil, gatewayPassword: nil)
        XCTAssertTrue(args.contains("-gfx"))
    }

    func testExtraArgs() {
        var p = makeProfile()
        p.extraArgs = """
        # 注释行
        /kbd:remap:0x1e=0x1f

        /timeout:60000
        """
        let args = ArgumentBuilder.build(profile: p, password: nil, gatewayPassword: nil)
        XCTAssertTrue(args.contains("/kbd:remap:0x1e=0x1f"))
        XCTAssertTrue(args.contains("/timeout:60000"))
        XCTAssertFalse(args.contains { $0.hasPrefix("#") })
        XCTAssertEqual(args.filter { $0 == "/timeout:60000" }.count, 1)
    }

    func testKeyboardLayout() {
        var p = makeProfile()
        p.keyboardLayout = "0x00000804"
        p.keyboardUnicode = false
        p.grabKeyboard = false
        let args = ArgumentBuilder.build(profile: p, password: nil, gatewayPassword: nil)
        XCTAssertTrue(args.contains("/kbd:layout:0x00000804,unicode:off"))
        XCTAssertTrue(args.contains("-grab-keyboard"))
    }

    func testWindowTitleOverride() {
        var p = makeProfile()
        p.windowTitle = "办公室电脑"
        let args = ArgumentBuilder.build(profile: p, password: nil, gatewayPassword: nil)
        XCTAssertTrue(args.contains("/t:办公室电脑"))
    }
}
