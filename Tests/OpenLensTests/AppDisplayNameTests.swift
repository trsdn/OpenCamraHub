import XCTest

/// Pins how the app can be called OpenCamraHub while its bundle is still
/// `OpenLens.app`.
///
/// Finder, Launchpad and Spotlight show a localized display name only when the
/// unlocalized `CFBundleDisplayName` equals the bundle's folder name; otherwise
/// macOS assumes the user renamed the app and shows the folder name. The folder
/// has to stay `OpenLens.app` (the broker profile declares it),
/// so the new name lives in `en.lproj/InfoPlist.strings`. Writing OpenCamraHub
/// into Info.plist looks like the obvious fix and silently brings "OpenLens"
/// back everywhere a person looks for the app.
final class AppDisplayNameTests: XCTestCase {
    private let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    private func appInfoPlist() throws -> [String: Any] {
        let data = try Data(contentsOf: root.appendingPathComponent("Sources/OpenLens/Info.plist"))
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        return try XCTUnwrap(plist as? [String: Any])
    }

    private func localizedInfoStrings() throws -> [String: String] {
        let url = root.appendingPathComponent("Sources/OpenLens/en.lproj/InfoPlist.strings")
        let data = try Data(contentsOf: url)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        return try XCTUnwrap(plist as? [String: String])
    }

    func testInfoPlistDisplayNameMatchesTheBundleFolder() throws {
        let info = try appInfoPlist()
        XCTAssertEqual(
            info["CFBundleDisplayName"] as? String,
            "OpenLens",
            "Must equal the OpenLens.app folder name, or Finder shows the folder name instead of the localized one."
        )
        XCTAssertEqual(info["LSHasLocalizedDisplayName"] as? Bool, true)
    }

    /// The Help menu and the README badges read these, and the standard
    /// requires a release build to carry them (I02, I03).
    func testTheBundleNamesItsRepositoryIssueTrackerAndLicense() throws {
        let info = try appInfoPlist()
        XCTAssertEqual(info["OCHRepositoryURL"] as? String, "https://github.com/trsdn/OpenCamraHub")
        XCTAssertEqual(info["OCHIssueTrackerURL"] as? String, "https://github.com/trsdn/OpenCamraHub/issues")
        XCTAssertEqual(info["OCHLicenseIdentifier"] as? String, "MIT")
        let copyright = try XCTUnwrap(info["NSHumanReadableCopyright"] as? String)
        XCTAssertTrue(copyright.contains("MIT"), "The copyright line should name the license the badge shows.")
        let license = try String(contentsOf: root.appendingPathComponent("LICENSE"), encoding: .utf8)
        XCTAssertTrue(license.hasPrefix("MIT License"), "OCHLicenseIdentifier must match the LICENSE file.")
    }

    func testThePublicNameComesFromTheLocalizedStrings() throws {
        let strings = try localizedInfoStrings()
        XCTAssertEqual(strings["CFBundleDisplayName"], "OpenCamraHub")
        XCTAssertEqual(strings["CFBundleName"], "OpenCamraHub")
    }
}
