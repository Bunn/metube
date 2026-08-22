import SwiftUI

struct BrowserCommands: Commands {
    @FocusedValue(\.browserController) private var browser

    var body: some Commands {
        CommandMenu("Navigate") {
            Button("Open Location…") {
                browser?.requestAddressFocus()
            }
            .keyboardShortcut("l", modifiers: .command)

            Divider()

            Button("Back") {
                browser?.goBack()
            }
            .keyboardShortcut("[", modifiers: .command)
            .disabled(browser?.canGoBack != true)

            Button("Forward") {
                browser?.goForward()
            }
            .keyboardShortcut("]", modifiers: .command)
            .disabled(browser?.canGoForward != true)

            Button("Reload") {
                browser?.reload()
            }
            .keyboardShortcut("r", modifiers: .command)

            Button("YouTube Home") {
                browser?.browseYouTube()
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])

            Divider()

            Button("Move Video to Menu Bar") {
                browser?.moveVideoToMenuBar()
            }
            .keyboardShortcut("m", modifiers: [.command, .option])
            .disabled(browser?.canMoveVideoToMenuBar != true || browser?.isVideoInMenuBar == true)
        }
    }
}
