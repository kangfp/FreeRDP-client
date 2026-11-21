import SwiftUI
import FreeRDPKit

enum SidebarItem: Hashable {
    case profile(UUID)
    case session(UUID)
}

struct ContentView: View {
    @EnvironmentObject private var store: ProfileStore
    @EnvironmentObject private var sessions: SessionManager

    @State private var selection: SidebarItem?
    @State private var searchText = ""
    @State private var errorMessage: String?
    @State private var profileToDelete: ConnectionProfile?

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection,
                        searchText: $searchText,
                        connect: connect,
                        requestDelete: { profileToDelete = $0 })
        } detail: {
            detailView
        }
        .alert("无法连接", isPresented: Binding(get: { errorMessage != nil },
                                               set: { if !$0 { errorMessage = nil } })) {
            Button("好", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .confirmationDialog("删除连接「\(profileToDelete?.name ?? "")」？",
                            isPresented: Binding(get: { profileToDelete != nil },
                                                 set: { if !$0 { profileToDelete = nil } }),
                            titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                if let p = profileToDelete {
                    if case .profile(let id) = selection, id == p.id { selection = nil }
                    store.delete(p)
                }
                profileToDelete = nil
            }
            Button("取消", role: .cancel) { profileToDelete = nil }
        } message: {
            Text("保存的密码也会从钥匙串中移除。")
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectProfile)) { note in
            if let id = note.object as? UUID {
                selection = .profile(id)
            }
        }
        .onAppear {
            if selection == nil, let first = store.profiles.first {
                selection = .profile(first.id)
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .profile(let id):
            if let binding = store.binding(for: id) {
                ProfileDetailView(profile: binding, connect: connect)
                    .id(id)
            } else {
                emptyState
            }
        case .session(let id):
            if sessions.sessions.contains(where: { $0.id == id }) {
                SessionLogView(sessionID: id)
            } else {
                emptyState
            }
        case nil:
            emptyState
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "desktopcomputer.and.arrow.down")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("选择左侧的连接，或新建一个")
                .foregroundStyle(.secondary)
            Button("新建连接") {
                let p = store.addProfile()
                selection = .profile(p.id)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func connect(_ profile: ConnectionProfile) {
        do {
            let id = try sessions.connect(profile: profile)
            selection = .session(id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
