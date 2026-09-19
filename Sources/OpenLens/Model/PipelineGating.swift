/// The rules that decide when the physical camera and the lamps may be touched.
///
/// Kept pure because `AppModel` owns the hardware and no test can build one,
/// while every regression here was a wrong answer to one of these questions.
enum PipelineGating {
    /// Someone has to be looking: a call has the virtual camera open, or our
    /// preview is on screen. Pause overrides both, because a paused app hands
    /// the camera back and lets its light go out.
    static func needsCamera(isPaused: Bool, isStreaming: Bool, previewWanted: Bool) -> Bool {
        !isPaused && (isStreaming || previewWanted)
    }

    /// A pause darkens the lamps on purpose. Anything that applies a scene's
    /// lighting while paused would switch them straight back on.
    static func shouldApplyLighting(isPaused: Bool) -> Bool {
        !isPaused
    }
}
