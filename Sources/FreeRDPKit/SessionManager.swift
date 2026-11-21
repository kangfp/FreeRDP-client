import Foundation
import Combine

/// 管理 FreeRDP 子进程：启动、日志收集、断开。
public final class SessionManager: ObservableObject {
    public static let shared = SessionManager()

    public enum State: Equatable {
        case running
        case ended(Int32)
        case launchFailed(String)

        public var isActive: Bool {
            if case .running = self { return true }
            return false
        }
    }

    public struct Session: Identifiable {
        public let id = UUID()
        public let profileID: UUID
        public let profileName: String
        public let host: String
        public let binaryPath: String
        public let startedAt = Date()
        public var state: State = .running
        public var log: [String] = []
        fileprivate var process: Process?

        /// 看门狗包装进程的 PID (测试与诊断用)
        public var processPID: Int32? { process?.processIdentifier }
    }

    @Published public private(set) var sessions: [Session] = []

    private let maxLogLines = 5000

    /// 看门狗包装脚本：
    /// - freerdp 作为后台子进程启动, `<&0` 显式继承 stdin (参数经 /args-from:stdin 传入)
    /// - 每秒检查父进程 (本应用) 是否存活；应用退出/崩溃/被强杀时立即终止 freerdp
    /// - 收到 SIGTERM/SIGINT (正常断开) 时转发给 freerdp, 并透传其退出码
    /// - cleanup 先 TERM 后 KILL：freerdp 在早期连接阶段收到 TERM 可能不退出
    ///   (信号标志被连接流程消费)，宽限 3 秒后必须 SIGKILL 兜底
    static let watchdogScript = """
    PARENT=$PPID
    "$1" /args-from:stdin <&0 &
    CHILD=$!
    cleanup() {
        kill -TERM "$CHILD" 2>/dev/null
        i=0
        while [ "$i" -lt 30 ] && kill -0 "$CHILD" 2>/dev/null; do
            sleep 0.1
            i=$((i + 1))
        done
        kill -KILL "$CHILD" 2>/dev/null
    }
    trap cleanup TERM INT
    while kill -0 "$PARENT" 2>/dev/null && kill -0 "$CHILD" 2>/dev/null; do
        sleep 1
    done
    cleanup
    wait "$CHILD"
    exit $?
    """

    public init() {}

    // MARK: - 启动

    public enum LaunchError: LocalizedError {
        case binaryNotFound
        case emptyHost
        case spawnFailed(String)

        public var errorDescription: String? {
            switch self {
            case .binaryNotFound: return "找不到 FreeRDP 客户端程序，请先安装 (brew install freerdp) 或在「高级」中指定路径。"
            case .emptyHost: return "请先填写主机地址。"
            case .spawnFailed(let msg): return "启动失败：\(msg)"
            }
        }
    }

    @discardableResult
    public func connect(profile: ConnectionProfile) throws -> UUID {
        guard !profile.host.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw LaunchError.emptyHost
        }
        guard let binary = FreeRDPBinary.resolve(for: profile) else {
            throw LaunchError.binaryNotFound
        }

        let password = KeychainHelper.load(account: KeychainHelper.account(for: profile.id))
        let gatewayPassword = KeychainHelper.load(account: KeychainHelper.gatewayAccount(for: profile.id))
        let args = ArgumentBuilder.build(profile: profile, password: password, gatewayPassword: gatewayPassword)

        let proc = Process()
        // 经看门狗包装启动：应用死亡 (含崩溃/强退) 时连接进程会被自动终止。
        // 参数仍经 stdin 传入，避免密码出现在 ps 进程列表中。
        proc.executableURL = URL(fileURLWithPath: "/bin/sh")
        proc.arguments = ["-c", Self.watchdogScript, "freerdp-watchdog", binary.path]
        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        proc.standardInput = stdinPipe
        proc.standardOutput = stdoutPipe
        proc.standardError = stderrPipe
        proc.currentDirectoryURL = URL(fileURLWithPath: NSHomeDirectory())

        var session = Session(profileID: profile.id,
                              profileName: profile.name,
                              host: profile.host,
                              binaryPath: binary.path)
        session.process = proc
        let sessionID = session.id
        sessions.append(session)

        proc.terminationHandler = { [weak self] p in
            DispatchQueue.main.async {
                self?.updateState(sessionID, state: .ended(p.terminationStatus))
            }
        }

        attachLogHandler(stdoutPipe.fileHandleForReading, sessionID: sessionID)
        attachLogHandler(stderrPipe.fileHandleForReading, sessionID: sessionID)

        do {
            try proc.run()
        } catch {
            sessions.removeAll { $0.id == sessionID }
            throw LaunchError.spawnFailed(error.localizedDescription)
        }

        // 写入全部参数后关闭 stdin（EOF 表示参数结束）
        let payload = args.joined(separator: "\n") + "\n"
        stdinPipe.fileHandleForWriting.write(Data(payload.utf8))
        try? stdinPipe.fileHandleForWriting.close()

        appendLog(sessionID, lines: ["[客户端] 已启动 \(binary.lastPathComponent)，目标 \(profile.host):\(profile.port)"])
        return sessionID
    }

    private func attachLogHandler(_ handle: FileHandle, sessionID: UUID) {
        handle.readabilityHandler = { [weak self] h in
            let data = h.availableData
            guard !data.isEmpty else {
                h.readabilityHandler = nil
                return
            }
            if let text = String(data: data, encoding: .utf8) {
                let lines = text.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
                DispatchQueue.main.async {
                    self?.appendLog(sessionID, lines: lines)
                }
            }
        }
    }

    private func appendLog(_ id: UUID, lines: [String]) {
        guard let idx = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[idx].log.append(contentsOf: lines)
        if sessions[idx].log.count > maxLogLines {
            sessions[idx].log.removeFirst(sessions[idx].log.count - maxLogLines)
        }
    }

    private func updateState(_ id: UUID, state: State) {
        guard let idx = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[idx].state = state
        if case .ended(let code) = state {
            appendLog(id, lines: ["[客户端] 会话结束，退出码 \(code)"])
        }
    }

    // MARK: - 控制

    public func disconnect(_ id: UUID) {
        guard let idx = sessions.firstIndex(where: { $0.id == id }),
              let proc = sessions[idx].process, proc.isRunning else { return }
        proc.terminate()
    }

    public func clearLog(_ id: UUID) {
        guard let idx = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[idx].log.removeAll()
    }

    public func removeEndedSessions() {
        sessions.removeAll { !$0.state.isActive }
    }

    /// 应用退出时调用：先礼后兵。
    /// SIGTERM 给看门狗 (转发 freerdp 优雅断开)，最多等 3 秒；
    /// 仍存活的先 SIGKILL 其 freerdp 子进程再杀看门狗，避免留孤儿。
    public func terminateAll() {
        let procs = sessions.compactMap { $0.process }.filter { $0.isRunning }
        guard !procs.isEmpty else { return }
        for proc in procs { proc.terminate() }

        let deadline = Date().addingTimeInterval(3.0)
        while Date() < deadline, procs.contains(where: { $0.isRunning }) {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }

        for proc in procs where proc.isRunning {
            for child in childPIDs(of: proc.processIdentifier) {
                kill(child, SIGKILL)
            }
            kill(proc.processIdentifier, SIGKILL)
        }
    }

    private func childPIDs(of pid: Int32) -> [Int32] {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        proc.arguments = ["-P", String(pid)]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        do {
            try proc.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            proc.waitUntilExit()
            let text = String(data: data, encoding: .utf8) ?? ""
            return text.split(separator: "\n").compactMap { Int32($0.trimmingCharacters(in: .whitespaces)) }
        } catch {
            return []
        }
    }

    public func activeSessions(for profileID: UUID) -> [Session] {
        sessions.filter { $0.profileID == profileID && $0.state.isActive }
    }
}
