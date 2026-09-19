import AppKit
import Foundation
import os.log

/// Checks GitHub Releases for a newer OpenCamraHub and offers its disk image.
///
/// It does not install anything. A sandboxed app may neither mount a disk
/// image nor replace itself in /Applications, which is why the in-app installer
/// failed (#41). Downloading goes through the browser, and the person drags the
/// new app over the old one; scenes and settings survive because they belong
/// to the bundle identifier, not to the copy on disk.
@MainActor
final class UpdateManager: ObservableObject {
    enum State: Equatable {
        case idle
        case checking
        case upToDate
        case available(AvailableUpdate)
        case failed(String)
    }

    @Published private(set) var state: State = .idle

    @Published var automaticChecksEnabled: Bool {
        didSet {
            guard automaticChecksEnabled != oldValue else { return }
            UserDefaults.standard.set(automaticChecksEnabled, forKey: Self.automaticChecksKey)
            if automaticChecksEnabled { startAutomaticChecks() } else { stopAutomaticChecks() }
        }
    }

    private static let automaticChecksKey = "updates.automaticChecks.v1"
    private static let automaticCheckInterval: TimeInterval = 24 * 60 * 60

    private let log = Logger(subsystem: OpenLensID.appBundleID, category: "updates")
    private var lastAutomaticCheck: Date?
    private var automaticCheckTask: Task<Void, Never>?

    init() {
        automaticChecksEnabled = UserDefaults.standard.object(forKey: Self.automaticChecksKey) as? Bool ?? true
    }

    var isBusy: Bool { state == .checking }

    private var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    // MARK: - Automatic checks

    func startAutomaticChecks() {
        automaticCheckTask?.cancel()
        guard automaticChecksEnabled else { return }
        // Wakes hourly but checks at most once a day: a Mac that sleeps through
        // the night would otherwise miss a plain 24-hour timer indefinitely.
        automaticCheckTask = Task { [weak self] in
            while !Task.isCancelled {
                if let self, self.isAutomaticCheckDue {
                    await self.check(userInitiated: false)
                }
                try? await Task.sleep(for: .seconds(60 * 60))
            }
        }
    }

    func stopAutomaticChecks() {
        automaticCheckTask?.cancel()
        automaticCheckTask = nil
    }

    private var isAutomaticCheckDue: Bool {
        guard let lastAutomaticCheck else { return true }
        return Date().timeIntervalSince(lastAutomaticCheck) >= Self.automaticCheckInterval
    }

    // MARK: - Check, download, dismiss

    /// A failed background check stays in the log: being offline is not worth a
    /// banner over the preview. A check the user asked for always answers.
    func check(userInitiated: Bool) async {
        guard !isBusy else { return }
        if case .available = state, !userInitiated { return }
        if userInitiated {
            state = .checking
        } else {
            lastAutomaticCheck = Date()
        }

        do {
            var request = URLRequest(url: ReleaseCheck.latestReleaseURL, timeoutInterval: 20)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            if let update = try ReleaseCheck.update(fromLatestRelease: data, currentVersion: currentVersion) {
                log.notice("Update available: \(update.version, privacy: .public)")
                state = .available(update)
            } else {
                log.info("No update available")
                state = userInitiated ? .upToDate : .idle
            }
        } catch is CancellationError {
            state = .idle
        } catch {
            log.error("Update check failed: \(error.localizedDescription, privacy: .public)")
            state = userInitiated ? .failed(error.localizedDescription) : .idle
        }
    }

    /// Hands the disk image to the browser, which saves it to Downloads. The
    /// banner stays up so the installation steps remain in view.
    func download() {
        guard case .available(let update) = state else { return }
        NSWorkspace.shared.open(update.downloadURL)
    }

    func showReleaseNotes() {
        guard case .available(let update) = state else { return }
        NSWorkspace.shared.open(update.releaseURL)
    }

    /// Hides the offer; the next daily check brings it back.
    func dismiss() {
        state = .idle
    }
}
