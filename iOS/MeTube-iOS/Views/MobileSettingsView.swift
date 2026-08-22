import SwiftUI

struct MobileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(PlaybackExperience.storageKey)
    private var playbackExperience = PlaybackExperience.defaultValue.rawValue

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Watch videos using", selection: $playbackExperience) {
                        ForEach(PlaybackExperience.allCases) { experience in
                            Text(experience.title).tag(experience.rawValue)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("YouTube Playback")
                } footer: {
                    Text(selectedExperience.detail)
                }

                Section("Media") {
                    Label("Inline playback and system fullscreen", systemImage: "arrow.up.left.and.arrow.down.right")
                    Label("Picture in Picture when available", systemImage: "pip")
                    Label("AirPlay", systemImage: "airplayvideo")
                }

                Section("Privacy") {
                    Label("YouTube-specific protection is active", systemImage: "shield.checkered")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
    }

    private var selectedExperience: PlaybackExperience {
        PlaybackExperience(rawValue: playbackExperience) ?? .defaultValue
    }
}
