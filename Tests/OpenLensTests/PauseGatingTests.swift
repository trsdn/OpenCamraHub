import XCTest

/// Pins the answers `AppModel` gets when it asks whether it may touch the
/// camera or the lamps.
///
/// Changing scene, camera or quality used to start the capture session and
/// apply the scene's lighting unconditionally, so a paused app woke the camera
/// light and switched the lamps back on. Both now ask these questions first.
final class PauseGatingTests: XCTestCase {
    func testPauseKeepsTheCameraOffWhateverElseIsWanted() {
        XCTAssertFalse(PipelineGating.needsCamera(isPaused: true, isStreaming: true, previewWanted: true))
        XCTAssertFalse(PipelineGating.needsCamera(isPaused: true, isStreaming: true, previewWanted: false))
        XCTAssertFalse(PipelineGating.needsCamera(isPaused: true, isStreaming: false, previewWanted: true))
    }

    func testACallAloneKeepsTheCameraOn() {
        XCTAssertTrue(PipelineGating.needsCamera(isPaused: false, isStreaming: true, previewWanted: false))
    }

    func testTheVisiblePreviewAloneKeepsTheCameraOn() {
        XCTAssertTrue(PipelineGating.needsCamera(isPaused: false, isStreaming: false, previewWanted: true))
    }

    func testNobodyWatchingMeansNoCamera() {
        XCTAssertFalse(PipelineGating.needsCamera(isPaused: false, isStreaming: false, previewWanted: false))
    }

    func testLightingIsOnlyAppliedWhileRunning() {
        XCTAssertTrue(PipelineGating.shouldApplyLighting(isPaused: false))
        XCTAssertFalse(PipelineGating.shouldApplyLighting(isPaused: true))
    }
}
