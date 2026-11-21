import SwiftUI
import FreeRDPKit

struct SessionLogView: View {
    let sessionID: UUID
    @EnvironmentObject private var sessions: SessionManager

    private var session: SessionManager.Session? {
        sessions.sessions.first { $0.id == sessionID }
    }

    var body: some View {
        if let session {
            VStack(spacing: 0) {
                header(session)
                Divider()
                logList(session)
            }
            .navigationTitle("会话：\(session.profileName)")
            .navigationSubtitle(session.host)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        sessions.clearLog(sessionID)
                    } label: {
                        Label("清空日志", systemImage: "eraser")
                    }
                    if session.state.isActive {
                        Button(role: .destructive) {
                            sessions.disconnect(sessionID)
                        } label: {
                            Label("断开", systemImage: "stop.fill")
                        }
                        .tint(.red)
                    }
                }
            }
        } else {
            Text("会话不存在")
                .foregroundStyle(.secondary)
        }
    }

    private func header(_ session: SessionManager.Session) -> some View {
        HStack(spacing: 10) {
            switch session.state {
            case .running:
                Label("运行中", systemImage: "play.circle.fill")
                    .foregroundStyle(.green)
            case .ended(let code):
                Label(code == 0 ? "已结束" : "已退出 (代码 \(code))",
                      systemImage: code == 0 ? "checkmark.circle" : "exclamationmark.circle")
                    .foregroundStyle(code == 0 ? Color.secondary : Color.orange)
            case .launchFailed(let msg):
                Label(msg, systemImage: "xmark.circle")
                    .foregroundStyle(.red)
            }
            Text(session.startedAt, style: .time)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(session.binaryPath)
                .font(.caption)
                .monospaced()
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
        }
        .font(.callout)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func logList(_ session: SessionManager.Session) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(Array(session.log.enumerated()), id: \.offset) { index, line in
                        Text(line)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(index)
                    }
                }
                .padding(10)
            }
            .background(Color(nsColor: .textBackgroundColor))
            .onChange(of: session.log.count) { _, _ in
                if let last = session.log.indices.last {
                    proxy.scrollTo(last, anchor: .bottom)
                }
            }
            .onAppear {
                if let last = session.log.indices.last {
                    proxy.scrollTo(last, anchor: .bottom)
                }
            }
        }
    }
}
