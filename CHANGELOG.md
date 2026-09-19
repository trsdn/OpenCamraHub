# Changelog

All notable changes to OpenLens are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and OpenLens uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- OpenLens is now called **OpenCamraHub**. The app, its menu, the camera that
  Teams, Zoom and Meet list, and the Stream Deck plugin show the new name.
  Nothing else changes: the app still installs as `OpenLens.app`, keeps its
  scenes and settings, stays selected as the camera in conferencing apps, and
  keeps updating itself.

### Added

- Stream Deck and OpenDeck keys: every key's label can be switched off or set
  to a template with placeholders such as `{scene}`, `{light}`, `{brightness}`
  and `{zoom}`.
- Pressing the live scene's key again pauses, and a further press resumes.
- Zoom keys show a magnifier with plus or minus, and brightness keys a large
  or small sun; light keys are labelled by the part of the light's name that
  tells it apart, such as "Links" and "Rechts".

### Fixed

- A label changed in a key's settings applies at once instead of after the
  next profile switch.
- The deck plugin writes its version to the deck app's log when it starts, so
  an outdated installed copy is noticed. An outdated copy from before the
  reconnect fix used up its file descriptors and crashed after login (#34).

## [0.3.1] - 2026-09-19

### Changed

- The scene and pause shortcuts are now Control-Option-1 to 9 and
  Control-Option-P instead of Option-only combinations, which stole ordinary
  characters on German and other keyboard layouts (#20).

### Fixed

- Entering an invalid Key Light address no longer crashes the app; it shows an
  error instead (#22).
- Out-of-range numbers sent to the control interface no longer crash the app
  (#19).
- A light can be added manually even when others were already found, and the
  address field is usable and submits on Return (#25).
- Changing one Key Light setting no longer overwrites its other settings with
  stale values (#21).
- Selecting a scene applies that scene, not the one selected before it (#16).
- Changing scene, camera or quality while paused no longer switches the camera
  and lights back on (#17).
- The "stays sharp up to" zoom limit updates when the camera resolution
  changes (#18).
- A scene name being typed is kept when switching scenes without pressing
  Return (#23).
- Value fields in the inspector show the current scene's value after switching
  scenes, and an unfinished entry can no longer land in another scene.
- Semi-transparent overlays no longer brighten the picture sent to calls (#26).
- Colours are encoded in the correct video range, so saturated colours match
  between the preview and calls (#24).

[Unreleased]: https://github.com/trsdn/OpenCamraHub/compare/v0.3.1...HEAD
[0.3.1]: https://github.com/trsdn/OpenCamraHub/compare/v0.3.0...v0.3.1
