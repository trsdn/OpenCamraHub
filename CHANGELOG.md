# Changelog

All notable changes to OpenLens are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and OpenLens uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.4.3] - 2026-09-21

### Added

- A **Settings** window (⌘,) holding the update preference, which used to be a
  menu item.
- The window title names the live scene, in the title bar and the Window menu.

### Changed

- Scene tiles are buttons: focusable, activatable from the keyboard, and
  announced by VoiceOver with the scene, its camera, its zoom and its shortcut.
  They were a picture beside two labels that happened to react to a click.
- Deleting a scene asks first and is marked as destructive. It takes the
  framing, corrections, overlay and lighting with it, and cannot be undone.

### Fixed

- Icon-only controls carry names for VoiceOver: the scene-lighting toggle used
  to be announced as "theatermasks", and the light menu, the refresh button and
  the zoom stepper had no name at all.

## [0.4.2] - 2026-09-20

### Added

- **Help › OpenCamraHub on GitHub** and **Help › Report an Issue…** open the
  project and its issue tracker. The app carries its repository, issue tracker,
  description, license and copyright in its bundle.

### Fixed

- Key Light discovery recovers on its own after the network search fails. It
  used to stay dead until the app was restarted, so lights stayed missing
  (#38). The failure is also logged with its cause instead of `<private>`.
- The Key Light brightness and colour temperature sliders announce which light
  they belong to and their current value to VoiceOver, instead of reading as an
  unnamed "slider".
- After the app replaces its own camera extension, losing contact with it is
  logged as a known consequence naming the restart that fixes it, instead of as
  an error that reads like a defect (#43).

## [0.4.1] - 2026-09-19

### Changed

- Updates are offered, not installed: when a newer version is out, a banner
  offers **Download** and explains how to install it. The previous in-app
  installer could not work in a sandboxed app and failed with an `hdiutil`
  error (#41). Copies older than this one show that error once; install this
  version by hand, and later updates use the new flow.

## [0.4.0] - 2026-09-19

### Changed

- OpenLens is now called **OpenCamraHub**. The app, its menu, the camera that
  Teams, Zoom and Meet list, and the Stream Deck plugin show the new name.
  Nothing else changes: the app still installs as `OpenLens.app`, keeps its
  scenes and settings, stays selected as the camera in conferencing apps, and
  keeps updating itself.
- Finder, Launchpad and Spotlight show the app as OpenCamraHub as well, although
  its folder is still `OpenLens.app`.

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

[Unreleased]: https://github.com/trsdn/OpenCamraHub/compare/v0.4.3...HEAD
[0.4.3]: https://github.com/trsdn/OpenCamraHub/compare/v0.4.2...v0.4.3
[0.4.2]: https://github.com/trsdn/OpenCamraHub/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/trsdn/OpenCamraHub/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/trsdn/OpenCamraHub/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/trsdn/OpenCamraHub/compare/v0.3.0...v0.3.1
