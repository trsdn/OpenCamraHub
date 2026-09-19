import SwiftUI

/// The app menu's update items. A separate view so the menu follows the
/// manager's state; the scene body only observes `AppModel`.
struct UpdateCommands: View {
    @ObservedObject var updates: UpdateManager

    var body: some View {
        Button("Check for Updates…") {
            Task { await updates.check(userInitiated: true) }
        }
        .disabled(updates.isBusy)
        Toggle("Check for Updates Automatically", isOn: $updates.automaticChecksEnabled)
    }
}

/// Offers a downloaded update, and answers a check the user asked for.
///
/// Installing restarts OpenLens and swaps the camera extension, so a call that
/// is using the camera loses its picture for a few seconds. The button says so
/// rather than letting that be a surprise, but does not refuse: the user may
/// well want to update between two meetings without leaving a call first.
struct UpdateBanner: View {
    @ObservedObject var updates: UpdateManager
    @ObservedObject private var client: ExtensionClient

    init(model: AppModel) {
        self.updates = model.updates
        self.client = model.extensionClient
    }

    var body: some View {
        switch updates.state {
        case .idle:
            EmptyView()
        case .checking:
            pill("Checking for updates…", icon: "hourglass", tint: .secondary)
        case .upToDate:
            HStack(spacing: 8) {
                pill("OpenCamraHub is up to date", icon: "checkmark.circle", tint: .secondary)
                dismissButton
            }
        case .downloading(let version):
            pill("Downloading OpenCamraHub \(version)…", icon: "arrow.down.circle", tint: .secondary)
        case .readyToInstall(let version):
            HStack(spacing: 8) {
                pill("OpenCamraHub \(version) is ready to install", icon: "arrow.down.circle.fill", tint: .accentColor)
                Button("Install and Restart") {
                    Task { await updates.installAndRelaunch() }
                }
                .buttonStyle(.borderedProminent)
                .help(
                    client.isStreaming
                        ? "Your call will lose its picture for a few seconds while OpenCamraHub restarts."
                        :"OpenCamraHub quits, updates itself and opens again."
                )
                Button("Later") { Task { await updates.dismiss() } }
            }
        case .installing:
            pill("Installing the update…", icon: "hourglass", tint: .secondary)
        case .failed(let message):
            HStack(spacing: 8) {
                pill("Update failed: \(message)", icon: "exclamationmark.triangle.fill", tint: .orange)
                dismissButton
            }
        case .installFailed(let message):
            HStack(spacing: 8) {
                pill("Update failed: \(message)", icon: "exclamationmark.triangle.fill", tint: .red)
                Button("Restart OpenCamraHub") { ExtensionStatusBanner.relaunch() }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private var dismissButton: some View {
        Button("OK") { Task { await updates.dismiss() } }
    }

    private func pill(_ text: String, icon: String, tint: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.callout)
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
    }
}
