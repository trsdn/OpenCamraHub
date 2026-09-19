# Changelog

All notable changes to OpenLens are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and OpenLens uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

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

[Unreleased]: https://github.com/trsdn/OpenLens/compare/v0.3.1...HEAD
[0.3.1]: https://github.com/trsdn/OpenLens/compare/v0.3.0...v0.3.1
