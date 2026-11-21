import SwiftUI
import AppKit
import FreeRDPKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var isTerminating = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // SwiftUI 的 WindowGroup 不会可靠响应 applicationShouldTerminateAfterLastWindowClosed，
        // 这里显式监听窗口关闭：最后一个主窗口关掉就退出应用 (随后断开所有会话)。
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification, object: nil, queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, !self.isTerminating else { return }
                let hasMainWindow = NSApp.windows.contains { $0.isVisible && $0.canBecomeMain }
                if !hasMainWindow {
                    self.isTerminating = true
                    NSApp.terminate(nil)
                }
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        SessionManager.shared.terminateAll()
    }
}

@main
struct FreeRDPClientApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = ProfileStore()
    @StateObject private var sessions = SessionManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(sessions)
                .frame(minWidth: 860, minHeight: 560)
        }
        .defaultSize(width: 1060, height: 720)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("新建连接") {
                    let p = store.addProfile()
                    NotificationCenter.default.post(name: .selectProfile, object: p.id)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let selectProfile = Notification.Name("selectProfile")
}
