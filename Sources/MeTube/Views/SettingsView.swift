import SwiftUI

struct SettingsView: View {
    @AppStorage(MenuBarPopoverDismissalMode.storageKey)
    private var dismissalMode = MenuBarPopoverDismissalMode.defaultValue.rawValue

    var body: some View {
        Form {
            Section("Menu Bar Player") {
                Picker("When the popover is open", selection: $dismissalMode) {
                    ForEach(MenuBarPopoverDismissalMode.allCases) { mode in
                        Text(mode.title).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.radioGroup)

                Text("This setting affects the menu-bar popover. The detached floating player remains visible until you dock it or return to the main window.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 230)
        .scenePadding()
    }
}
