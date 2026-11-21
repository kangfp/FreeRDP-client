import SwiftUI
import FreeRDPKit

struct SidebarView: View {
    @EnvironmentObject private var store: ProfileStore
    @EnvironmentObject private var sessions: SessionManager

    @Binding var selection: SidebarItem?
    @Binding var searchText: String
    let connect: (ConnectionProfile) -> Void
    let requestDelete: (ConnectionProfile) -> Void

    private var filteredProfiles: [ConnectionProfile] {
        guard !searchText.isEmpty else { return store.profiles }
        let q = searchText.lowercased()
        return store.profiles.filter {
            $0.name.lowercased().contains(q) ||
            $0.host.lowercased().contains(q) ||
            $0.username.lowercased().contains(q)
        }
    }

    var body: some View {
        List(selection: $selection) {
            Section("连接") {
                ForEach(filteredProfiles) { profile in
                    ProfileRow(profile: profile)
                        .tag(SidebarItem.profile(profile.id))
                        .contextMenu {
                            Button("连接") { connect(profile) }
                            Button("复制配置") { store.duplicate(profile) }
                            Divider()
                            Button("删除…", role: .destructive) { requestDelete(profile) }
                        }
                }
            }

            if !sessions.sessions.isEmpty {
                Section("会话") {
                    ForEach(sessions.sessions) { session in
                        SessionRow(session: session)
                            .tag(SidebarItem.session(session.id))
                            .contextMenu {
                                if session.state.isActive {
                                    Button("断开", role: .destructive) { sessions.disconnect(session.id) }
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $searchText, placement: .sidebar, prompt: "搜索连接")
        .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 360)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    let p = store.addProfile()
                    selection = .profile(p.id)
                } label: {
                    Label("新建连接", systemImage: "plus")
                }
                .help("新建连接 (⌘N)")
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    sessions.removeEndedSessions()
                } label: {
                    Label("清理已结束会话", systemImage: "trash")
                }
                .help("清理已结束的会话记录")
                .disabled(!sessions.sessions.contains { !$0.state.isActive })
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                if let url = FreeRDPBinary.sdl ?? FreeRDPBinary.xfreerdp {
                    Text("FreeRDP: \(url.lastPathComponent)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("未检测到 FreeRDP，请运行 brew install freerdp")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }
}

private struct ProfileRow: View {
    let profile: ConnectionProfile
    @EnvironmentObject private var sessions: SessionManager

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "desktopcomputer")
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(profile.name)
                    .lineLimit(1)
                Text(profile.host.isEmpty ? "未设置主机" : profile.host + (profile.port == 3389 ? "" : ":\(profile.port)"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if !sessions.activeSessions(for: profile.id).isEmpty {
                Circle()
                    .fill(.green)
                    .frame(width: 7, height: 7)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct SessionRow: View {
    let session: SessionManager.Session

    var body: some View {
        HStack(spacing: 8) {
            statusIcon
            VStack(alignment: .leading, spacing: 1) {
                Text(session.profileName)
                    .lineLimit(1)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch session.state {
        case .running:
            Image(systemName: "play.circle.fill").foregroundStyle(.green)
        case .ended(let code):
            Image(systemName: code == 0 ? "checkmark.circle" : "exclamationmark.circle")
                .foregroundStyle(code == 0 ? Color.secondary : Color.orange)
        case .launchFailed:
            Image(systemName: "xmark.circle").foregroundStyle(.red)
        }
    }

    private var statusText: String {
        switch session.state {
        case .running: return "运行中 · \(session.host)"
        case .ended(let code): return code == 0 ? "已结束" : "已退出 (代码 \(code))"
        case .launchFailed(let msg): return msg
        }
    }
}
