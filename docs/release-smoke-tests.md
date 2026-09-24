# Release smoke tests

Every release is installed from its **published** artifact, the way a user gets
it, and launched before it counts as done. A notarized build is not necessarily
a working one: releases 0.1.0 and 0.1.1 passed every signing check and could not
be started at all (see AGENTS.md).

Each entry names the version, the date, what was exercised, and what was not.

## 0.4.6 (2026-09-24)

Patches 0.4.5, whose drag-to-reorder never actually started a drag in the
notarized build (#73). Exercised on an Apple silicon Mac, upgrading from
0.4.5:

- `gh release download v0.4.6`; the DMG matches its `.sha256`, and
  `provenance.json`'s recorded commit is the merged `Release 0.4.6` PR (#74).
- `spctl -a -vvv -t exec` *accepted, source=Notarized Developer ID*, both on
  the mounted DMG and again after installing.
- Quit the running 0.4.5, replaced `/Applications/OpenLens.app`, launched.
  The extension was replaced: `systemextensionsctl list` shows
  `com.trsdn.openlens.camera (0.4.6/83)` *activated enabled*, and `sysextd`
  logged nothing about it.

Not exercised: the drag gesture itself. 0.4.5's smoke test also didn't cover
it, which is exactly how a drag that never worked in the shipped build reached
users in the first place — this needs a manual check against the actual
release, not another local build, before it can be marked exercised here.

## 0.4.5 (2026-09-24)

Scene reordering (Move Left/Right, drag and drop) and the pause/idle-card
changes from #66, #67, #69 and #70. Exercised on an Apple silicon Mac with a
Cam Link 4K, upgrading from 0.4.4:

- `gh release download v0.4.5`; the DMG matches its `.sha256`, and
  `provenance.json`'s recorded commit is the merged `Release 0.4.5` PR (#71).
- `Contents/embedded.provisionprofile` present, `spctl -a -vvv -t exec`
  *accepted, source=Notarized Developer ID*, both on the mounted DMG and again
  after installing.
- Quit the running 0.4.4, replaced `/Applications/OpenLens.app`, launched.
  The window title bar reads *OpenCamraHub*, matching the localized display
  name.
- The extension was replaced: `systemextensionsctl list` shows
  `com.trsdn.openlens.camera (0.4.5/82)` *activated enabled*, and `sysextd`
  logged nothing about it in the five minutes around the launch.
- The app receives frames from the Cam Link 4K: the Scene panel reports
  *Receiving 1920 x 1080 · 30 fps*, and the picture is live in the preview.
- All previously saved scenes survived the install (they live in the sandbox
  container, keyed by bundle identifier, untouched by replacing the app
  bundle).

Not exercised: the drag gesture itself, or Move Left/Right, against a mouse —
this pass confirmed the release starts and streams, not the reordering
feature's own behaviour, which has unit coverage instead (`SceneSelectionTests`)
and no UI test harness in this project to drive a real drag.

## 0.4.4 (2026-09-21)

The release that undoes 0.4.3, which opened its settings window and nothing
else (#60). Exercised on an Apple silicon Mac with a Cam Link 4K, upgrading
from the rolled-back 0.4.2:

- `gh release download v0.4.4`; the DMG matches its `.sha256`.
- `Contents/embedded.provisionprofile` present,
  `spctl -a -vvv -t exec` *accepted, source=Notarized Developer ID*,
  `codesign --verify --deep --strict` valid after the install.
- **Launched with no saved window state at all**, which is the condition 0.4.3
  failed: a restored window hid the bug during its testing. The window server
  reports one on-screen layer-0 window titled *OpenCamraHub*, 1345×606, and no
  settings window. This is the check that has to be repeated for every release
  from here on.
- The control socket appeared and answered `state.get`, so the socket server —
  and with it `AppModel` — is up rather than merely the settings scene.
- Settings survived: all three scenes, their adjustments, the selected scene and
  its zoom of 1.43 came back from the sandbox container unchanged.
- `cameraAuthorized` is true and the four capture devices are listed.
- The extension was replaced: `systemextensionsctl list` shows
  `com.trsdn.openlens.camera (0.4.4/75)` *activated enabled*, its process is
  running, and `sysextd` logged nothing about it.

Completed the next evening, with the camera on and the lights on the network
again — the first release where the published camera was actually consumed:

- The app receives frames from the Cam Link 4K, and both Key Lights report
  `reachable`. The previous evening's `receivingFrames: false` and "the
  Internet connection appears to be offline" were the desk being powered down.
- A test process opened **OpenCamraHub** through `AVCaptureDeviceInput` and got
  100–121 frames in four seconds (~25–30 fps) at 1920×1080, `2vuy`. This is
  what 0.4.1 could not check for want of camera permission.
- The picture is real and stable: mean luma 52 on every frame, spread 0.1. The
  physical source measures 70 over the same scene, and the gap is the selected
  scene's grading and its 1.43 crop, so the render path is doing its work
  rather than passing the input through.

Two traps this probe walked into, worth avoiding next time:

- `2vuy` is *packed*, so `CVPixelBufferGetPlaneCount` is 0 and reading plane 0
  returns nothing. That reports mean luma 0.0 — indistinguishable from a black
  picture. Luma lives on the odd bytes of the single plane.
- A single run measured a frame-to-frame spread of 21 because it caught the
  session's first frames. Judge stability from a warm pipeline, or from the
  sequence rather than from min and max.

A verification note, because it cost time here: `osascript` reported zero
windows for the app, which looks exactly like the 0.4.3 failure. It was
`-25211`, missing accessibility permission. `CGWindowListCopyWindowInfo` needs
no such permission and answers even while the display sleeps — use that.

## 0.4.1 (2026-09-19)

Exercised on an Apple silicon Mac with a Cam Link 4K and two Key Lights,
upgrading from 0.4.0:

- Downloaded the release assets with `gh release download v0.4.1`; the ZIP and
  DMG checksums match their `.sha256` files.
- `Contents/embedded.provisionprofile` is present, and
  `spctl -a -vvv -t exec` reports *accepted, source=Notarized Developer ID*.
- The bundle has `CFBundleShortVersionString` 0.4.1, `CFBundleDisplayName`
  OpenLens with the localized name OpenCamraHub, and no AppUpdater bundle.
- Installed into `/Applications` over 0.4.0 and launched. The camera extension
  was replaced: `systemextensionsctl list` shows
  `com.trsdn.openlens.camera (0.4.1/59)` *activated enabled*.
- Finder and Spotlight name the app OpenCamraHub (`kMDItemDisplayName`).
- Saved settings survived the upgrade: compared against a copy taken before
  installing, 13 of 14 preferences are byte-identical, and the fourteenth
  (`scenes.v1`) decodes to the same three scenes.

Not exercised: frames from the virtual camera in a consuming app. The test
process that opened the camera had no camera permission, so it received none;
this needs a check in Teams, Zoom or Photo Booth.

## 0.4.0 (2026-09-19)

- Downloaded, checksums verified, provisioning profile present, Gatekeeper
  *accepted*.
- Installed over 0.3.1 and launched; extension `0.4.0/57` *activated enabled*.
- The app showed the live camera and *Ready — now turn your video on in Teams,
  Zoom or Meet*; conferencing apps list the camera as **OpenCamraHub**.
- Saved scenes, the selected scene and both Key Lights carried over.
- The 0.3.1 in-app updater found 0.4.0 but failed to install it (#41), which led
  to the download-based updates in 0.4.1.
