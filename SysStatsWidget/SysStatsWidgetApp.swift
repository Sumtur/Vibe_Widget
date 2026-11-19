import SwiftUI

@main
struct SysStatsWidgetApp: App {
    var body: some Scene {
        Window("System Stats", id: "main") {
            ContentView()
                .frame(minWidth: 360, minHeight: 220)
        }
    }
}

private struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "gauge.with.needle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)
            Text("System Stats Widget")
                .font(.title)
            Text("The desktop widget is bundled with this app. Build and run the app once, then add the widget from Notification Center (Edit Widgets) or by right-clicking the desktop (Edit Widgets on macOS 15+) and search for \"System Stats\".")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)
        }
        .padding()
    }
}
