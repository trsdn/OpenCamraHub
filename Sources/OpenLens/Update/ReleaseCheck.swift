import Foundation

/// A release newer than the running app, and where to get it.
struct AvailableUpdate: Equatable {
    let version: String
    /// The disk image, or the release page when the release has none.
    let downloadURL: URL
    let releaseURL: URL
}

/// Decides from GitHub's latest-release response whether there is an update.
///
/// The app is sandboxed, so it cannot mount a disk image or replace itself in
/// /Applications. It only finds the update; the person installs it by opening
/// the disk image, which keeps every setting because those are keyed on the
/// bundle identifier.
enum ReleaseCheck {
    static let latestReleaseURL = URL(
        string: "https://api.github.com/repos/trsdn/OpenCamraHub/releases/latest")!

    static func update(fromLatestRelease data: Data, currentVersion: String) throws -> AvailableUpdate? {
        let release = try JSONDecoder().decode(Release.self, from: data)
        guard !release.draft, !release.prerelease else { return nil }

        let version = release.tagName.hasPrefix("v") ? String(release.tagName.dropFirst()) : release.tagName
        guard isVersion(version, newerThan: currentVersion) else { return nil }

        let diskImage =
            release.assets.first { $0.name == "OpenLens-v\(version)-macOS-arm64.dmg" }
            ?? release.assets.first { $0.name == "OpenLens-\(version).dmg" }
        return AvailableUpdate(
            version: version,
            downloadURL: diskImage?.browserDownloadURL ?? release.htmlURL,
            releaseURL: release.htmlURL
        )
    }

    /// Numeric, component by component, so 0.10.0 is newer than 0.9.3. Anything
    /// that is not plain dotted numbers counts as not newer.
    static func isVersion(_ candidate: String, newerThan current: String) -> Bool {
        guard let new = components(candidate), let old = components(current) else { return false }
        for index in 0..<max(new.count, old.count) {
            let lhs = index < new.count ? new[index] : 0
            let rhs = index < old.count ? old[index] : 0
            if lhs != rhs { return lhs > rhs }
        }
        return false
    }

    private static func components(_ version: String) -> [Int]? {
        let parts = version.split(separator: ".", omittingEmptySubsequences: false).map { Int($0) }
        guard !parts.isEmpty, !parts.contains(nil) else { return nil }
        return parts.compactMap { $0 }
    }

    private struct Release: Decodable {
        let tagName: String
        let htmlURL: URL
        let draft: Bool
        let prerelease: Bool
        let assets: [Asset]

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlURL = "html_url"
            case draft, prerelease, assets
        }
    }

    private struct Asset: Decodable {
        let name: String
        let browserDownloadURL: URL

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
        }
    }
}
