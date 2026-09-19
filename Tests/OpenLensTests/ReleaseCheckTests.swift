import XCTest

final class ReleaseCheckTests: XCTestCase {
    private func release(
        tag: String,
        assets: [String] = [],
        draft: Bool = false,
        prerelease: Bool = false
    ) -> Data {
        let assetJSON = assets.map {
            #"{"name":"\#($0)","browser_download_url":"https://github.com/trsdn/OpenCamraHub/releases/download/\#(tag)/\#($0)"}"#
        }
        return Data(
            #"""
            {"tag_name":"\#(tag)","html_url":"https://github.com/trsdn/OpenCamraHub/releases/tag/\#(tag)",
             "draft":\#(draft),"prerelease":\#(prerelease),"assets":[\#(assetJSON.joined(separator: ","))]}
            """#.utf8
        )
    }

    private let releaseAssets = [
        "OpenLens-0.5.0.dmg",
        "OpenLens-v0.5.0-macOS-arm64.dmg",
        "OpenLens-v0.5.0-macOS-arm64.zip",
    ]

    func testANewerReleaseOffersItsDiskImage() throws {
        let update = try ReleaseCheck.update(
            fromLatestRelease: release(tag: "v0.5.0", assets: releaseAssets),
            currentVersion: "0.4.0"
        )
        XCTAssertEqual(update?.version, "0.5.0")
        XCTAssertEqual(update?.downloadURL.lastPathComponent, "OpenLens-v0.5.0-macOS-arm64.dmg")
        XCTAssertEqual(update?.releaseURL.absoluteString, "https://github.com/trsdn/OpenCamraHub/releases/tag/v0.5.0")
    }

    func testTheInstalledVersionIsNotAnUpdate() throws {
        XCTAssertNil(try ReleaseCheck.update(fromLatestRelease: release(tag: "v0.4.0"), currentVersion: "0.4.0"))
        XCTAssertNil(try ReleaseCheck.update(fromLatestRelease: release(tag: "v0.3.1"), currentVersion: "0.4.0"))
    }

    func testAReleaseWithoutTheDiskImageStillPointsSomewhereUseful() throws {
        let update = try ReleaseCheck.update(fromLatestRelease: release(tag: "v0.5.0"), currentVersion: "0.4.0")
        XCTAssertEqual(update?.downloadURL, update?.releaseURL)
    }

    func testDraftsAndPrereleasesAreIgnored() throws {
        XCTAssertNil(try ReleaseCheck.update(fromLatestRelease: release(tag: "v0.5.0", draft: true), currentVersion: "0.4.0"))
        XCTAssertNil(try ReleaseCheck.update(fromLatestRelease: release(tag: "v0.5.0", prerelease: true), currentVersion: "0.4.0"))
    }

    func testVersionsCompareNumericallyNotAlphabetically() {
        XCTAssertTrue(ReleaseCheck.isVersion("0.10.0", newerThan: "0.9.3"))
        XCTAssertTrue(ReleaseCheck.isVersion("1.0.0", newerThan: "0.99.99"))
        XCTAssertFalse(ReleaseCheck.isVersion("1.0", newerThan: "1.0.0"))
        XCTAssertFalse(ReleaseCheck.isVersion("0.5.0-beta", newerThan: "0.4.0"))
    }

    func testAnUnreadableResponseIsAnError() {
        XCTAssertThrowsError(try ReleaseCheck.update(fromLatestRelease: Data("{}".utf8), currentVersion: "0.4.0"))
    }
}
