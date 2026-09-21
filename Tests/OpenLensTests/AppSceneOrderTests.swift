import XCTest

/// Pins the order of the scenes in `OpenLensApp`.
///
/// SwiftUI opens the first scene in the body at launch. 0.4.3 shipped with
/// `Settings` first, so the app opened its settings window and nothing else:
/// no picture, no control socket, and no way to reach the main window, because
/// a `Window` scene that never opened is not in the Window menu either. A
/// restored window hid it during testing; a launch with no saved state did not.
final class AppSceneOrderTests: XCTestCase {
    func testTheMainWindowIsDeclaredBeforeSettings() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/OpenLens/OpenLensApp.swift")
        let source = try String(contentsOf: url, encoding: .utf8)

        let window = try XCTUnwrap(source.range(of: #"Window("OpenCamraHub""#))
        let settings = try XCTUnwrap(source.range(of: "Settings {"))
        XCTAssertLessThan(
            window.lowerBound,
            settings.lowerBound,
            "The Window scene must come first, or the app opens Settings at launch instead."
        )
    }
}
