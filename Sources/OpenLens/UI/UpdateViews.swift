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
        // Whether to check daily is a preference, so it lives in Settings (⌘,)
        // rather than in a menu.
    }
}

/// Offers a newer release, and answers a check the user asked for.
///
/// The app cannot install it itself (it is sandboxed), so the offer carries the
/// three steps that do: download, open, drag over the old copy.
struct UpdateBanner: View {
    @ObservedObject var updates: UpdateManager

    init(model: AppModel) {
        self.updates = model.updates
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
        case .available(let update):
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    pill(
                        "OpenCamraHub \(update.version) is available", icon: "arrow.down.circle.fill",
                        tint: .accentColor)
                    Button("Download") { updates.download() }
                        .buttonStyle(.borderedProminent)
                        .help("Saves the disk image to your Downloads folder.")
                    Button("What's New") { updates.showReleaseNotes() }
                    Button("Later") { updates.dismiss() }
                }
                Text(
                    "Open the downloaded disk image, drag OpenCamraHub into Applications and replace "
                        + "the old copy, then open it again. Your scenes and settings stay."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        case .failed(let message):
            HStack(spacing: 8) {
                pill("Update check failed: \(message)", icon: "exclamationmark.triangle.fill", tint: .orange)
                dismissButton
            }
        }
    }

    private var dismissButton: some View {
        Button("OK") { updates.dismiss() }
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
