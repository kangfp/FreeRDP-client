import Foundation
import Combine
import SwiftUI

/// 连接配置持久化到 ~/Library/Application Support/FreeRDPClient/profiles.json
/// 密码单独存钥匙串，不写入 JSON。
public final class ProfileStore: ObservableObject {
    @Published public var profiles: [ConnectionProfile] = [] {
        didSet { save() }
    }

    private let fileURL: URL
    private var loading = false

    public init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("FreeRDPClient", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("profiles.json")
        load()
    }

    private func load() {
        loading = true
        defer { loading = false }
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([ConnectionProfile].self, from: data) {
            profiles = decoded
        }
    }

    private func save() {
        guard !loading else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(profiles) else { return }
        try? data.write(to: fileURL, options: [.atomic])
        // 配置文件含用户名/主机等信息，收紧权限
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }

    // MARK: - 操作

    @discardableResult
    public func addProfile() -> ConnectionProfile {
        var p = ConnectionProfile()
        p.name = nextDefaultName()
        profiles.append(p)
        return p
    }

    private func nextDefaultName() -> String {
        let base = "新建连接"
        if !profiles.contains(where: { $0.name == base }) { return base }
        var i = 2
        while profiles.contains(where: { $0.name == "\(base) \(i)" }) { i += 1 }
        return "\(base) \(i)"
    }

    public func duplicate(_ profile: ConnectionProfile) {
        var copy = profile
        copy.id = UUID()
        copy.name = profile.name + " 副本"
        profiles.append(copy)
        // 复制钥匙串中的密码
        if let pw = KeychainHelper.load(account: KeychainHelper.account(for: profile.id)) {
            KeychainHelper.save(password: pw, account: KeychainHelper.account(for: copy.id))
        }
        if let gw = KeychainHelper.load(account: KeychainHelper.gatewayAccount(for: profile.id)) {
            KeychainHelper.save(password: gw, account: KeychainHelper.gatewayAccount(for: copy.id))
        }
    }

    public func delete(_ profile: ConnectionProfile) {
        profiles.removeAll { $0.id == profile.id }
        KeychainHelper.delete(account: KeychainHelper.account(for: profile.id))
        KeychainHelper.delete(account: KeychainHelper.gatewayAccount(for: profile.id))
    }

    public func binding(for id: UUID) -> Binding<ConnectionProfile>? {
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { self.profiles[index] },
            set: { self.profiles[index] = $0 }
        )
    }
}
