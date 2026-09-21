import SwiftUI

/// The Settings window, reached with ⌘, like every other Mac app.
///
/// Only what is *not* part of a scene belongs here. Framing, corrections,
/// overlay and lighting live in the inspector, because they are saved into the
/// selected scene; what is left is how the app behaves around them.
struct SettingsView: View {
    @ObservedObject var updates: UpdateManager

    var body: some View {
        Form {
            Section {
                Toggle("Check for updates automatically", isOn: $updates.automaticChecksEnabled)
                Text(
                    "Once a day the app asks GitHub whether a newer version exists, and offers it "
                        + "as a download. Nothing else is sent, and no identifier goes with the "
                        + "request. Switch this off and the app only checks when you ask it to."
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack {
                    Button("Check for Updates…") {
                        Task { await updates.check(userInitiated: true) }
                    }
                    .disabled(updates.isBusy)
                    if case .upToDate = updates.state {
                        Text("Up to date.").font(.caption).foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Updates")
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
    }
}
