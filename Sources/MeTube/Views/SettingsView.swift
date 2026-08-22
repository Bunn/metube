import SwiftUI

struct SettingsView: View {
    @AppStorage(NavigationBarPreferences.autoHideKey)
    private var automaticallyHideNavigationBar = NavigationBarPreferences.defaultAutoHide
    @AppStorage(NavigationBarPreferences.autoHideDelayKey)
    private var navigationBarAutoHideDelay = NavigationBarPreferences.defaultAutoHideDelay
    @AppStorage(MenuBarPopoverDismissalMode.storageKey)
    private var dismissalMode = MenuBarPopoverDismissalMode.defaultValue.rawValue
    @AppStorage(PlaybackExperience.storageKey)
    private var playbackExperience = PlaybackExperience.defaultValue.rawValue

    var body: some View {
        TabView {
            Form {
                Section("Navigation") {
                    Toggle("Automatically hide the browser toolbar", isOn: $automaticallyHideNavigationBar)

                    Picker("Hide after", selection: $navigationBarAutoHideDelay) {
                        ForEach(NavigationBarPreferences.supportedAutoHideDelays, id: \.self) { delay in
                            Text("\(Int(delay)) seconds").tag(delay)
                        }
                    }
                    .disabled(!automaticallyHideNavigationBar)
                }

                Section("Menu Bar Player") {
                    Picker("When the popover is open", selection: $dismissalMode) {
                        ForEach(MenuBarPopoverDismissalMode.allCases) { mode in
                            Text(mode.title).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.radioGroup)

                    Text("The detached floating player remains visible until you dock it or return to the main window.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("General", systemImage: "gearshape")
            }

            Form {
                Section("YouTube Playback") {
                    Picker("Watch videos using", selection: $playbackExperience) {
                        ForEach(PlaybackExperience.allCases) { experience in
                            VStack(alignment: .leading) {
                                Text(experience.title)
                                Text(experience.detail)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .tag(experience.rawValue)
                        }
                    }
                    .pickerStyle(.radioGroup)
                }

                Text("Changing this setting reloads the current video.")
                    .foregroundStyle(.secondary)
            }
            .formStyle(.grouped)
            .tabItem {
                Label("Playback", systemImage: "play.rectangle")
            }
        }
        .frame(width: 560, height: 360)
        .scenePadding()
    }
}
