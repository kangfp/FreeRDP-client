import XCTest
@testable import FreeRDPKit

/// 集成测试：真实启动 sdl-freerdp (连接被拒绝的地址, 进程会停在 SDL 对话框),
/// 验证断开与应用退出时的进程清理。
final class SessionManagerTests: XCTestCase {

    private func makeRefusedProfile() -> ConnectionProfile {
        var p = ConnectionProfile()
        p.name = "集成测试"
        p.host = "127.0.0.1"
        p.port = 9
        p.certPolicy = .ignore
        p.logLevel = .error
        return p
    }

    private func childPIDs(of pid: Int32) -> [Int32] {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        proc.arguments = ["-P", String(pid)]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        try? proc.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        proc.waitUntilExit()
        let text = String(data: data, encoding: .utf8) ?? ""
        return text.split(separator: "\n").compactMap { Int32($0.trimmingCharacters(in: .whitespaces)) }
    }

    private func isAlive(_ pid: Int32) -> Bool {
        kill(pid, 0) == 0 || errno == EPERM
    }

    /// 轮询等待条件成立, 期间转动 RunLoop 让主队列回调有机会执行
    private func waitUntil(timeout: TimeInterval = 12, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return condition()
    }

    func testTerminateAllKillsWatchdogAndFreeRDP() throws {
        guard FreeRDPBinary.sdl != nil else {
            throw XCTSkip("本机未安装 sdl-freerdp")
        }
        let manager = SessionManager()
        let id = try manager.connect(profile: makeRefusedProfile())
        guard let pid = manager.sessions.first(where: { $0.id == id })?.processPID else {
            return XCTFail("会话缺少进程 PID")
        }

        // 等 freerdp 子进程出现
        var children: [Int32] = []
        let spawned = waitUntil {
            children = self.childPIDs(of: pid)
            return !children.isEmpty
        }
        XCTAssertTrue(spawned, "freerdp 子进程未启动")

        // 模拟应用退出
        manager.terminateAll()

        let wrapperDead = waitUntil(timeout: 6) { !self.isAlive(pid) }
        let childrenDead = waitUntil(timeout: 6) { children.allSatisfy { !self.isAlive($0) } }
        XCTAssertTrue(wrapperDead, "看门狗进程未被终止")
        XCTAssertTrue(childrenDead, "freerdp 进程未被终止 (会留下孤儿连接)")
    }

    func testDisconnectTerminatesSession() throws {
        guard FreeRDPBinary.sdl != nil else {
            throw XCTSkip("本机未安装 sdl-freerdp")
        }
        let manager = SessionManager()
        let id = try manager.connect(profile: makeRefusedProfile())
        guard let pid = manager.sessions.first(where: { $0.id == id })?.processPID else {
            return XCTFail("会话缺少进程 PID")
        }
        let spawned = waitUntil { !self.childPIDs(of: pid).isEmpty }
        XCTAssertTrue(spawned, "freerdp 子进程未启动")

        manager.disconnect(id)

        let dead = waitUntil(timeout: 10) { !self.isAlive(pid) }
        XCTAssertTrue(dead, "断开后看门狗进程仍存活")
        let ended = waitUntil(timeout: 5) {
            manager.sessions.first(where: { $0.id == id })?.state.isActive == false
        }
        XCTAssertTrue(ended, "会话状态未更新为已结束")
    }
}
