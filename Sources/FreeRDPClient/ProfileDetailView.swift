import SwiftUI
import FreeRDPKit

struct ProfileDetailView: View {
    @Binding var profile: ConnectionProfile
    let connect: (ConnectionProfile) -> Void

    @State private var showCommandPreview = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ConnectionTab(profile: $profile)
                .tabItem { Label("连接", systemImage: "network") }
                .tag(0)
            DisplayTab(profile: $profile)
                .tabItem { Label("显示", systemImage: "display") }
                .tag(1)
            PerformanceTab(profile: $profile)
                .tabItem { Label("性能", systemImage: "gauge.with.dots.needle.67percent") }
                .tag(2)
            ResourcesTab(profile: $profile)
                .tabItem { Label("本地资源", systemImage: "arrow.left.arrow.right") }
                .tag(3)
            SecurityTab(profile: $profile)
                .tabItem { Label("安全", systemImage: "lock.shield") }
                .tag(4)
            AdvancedTab(profile: $profile)
                .tabItem { Label("高级", systemImage: "gearshape.2") }
                .tag(5)
        }
        .padding(.top, 8)
        .navigationTitle(profile.name)
        .navigationSubtitle(profile.host.isEmpty ? "未设置主机" : profile.host)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showCommandPreview = true
                } label: {
                    Label("命令行", systemImage: "terminal")
                }
                .help("预览将要执行的 FreeRDP 命令")

                Button {
                    connect(profile)
                } label: {
                    Label("连接", systemImage: "play.fill")
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(profile.host.trimmingCharacters(in: .whitespaces).isEmpty)
                .help("连接 (⌘↩)")
            }
        }
        .sheet(isPresented: $showCommandPreview) {
            CommandPreviewView(profile: profile)
        }
    }
}
