import SwiftUI

@main
struct MeTubeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("MeTube") {
            ContentView()
        }
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
        .defaultSize(width: 1_100, height: 720)
        .commands {
            CommandGroup(replacing: .newItem) {}
            BrowserCommands()
        }

        Settings {
            SettingsView()
        }
    }
}
