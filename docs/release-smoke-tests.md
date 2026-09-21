# Release smoke tests

Every release is installed from its **published** artifact, the way a user gets
it, and launched before it counts as done. A notarized build is not necessarily
a working one: releases 0.1.0 and 0.1.1 passed every signing check and could not
be started at all (see AGENTS.md).

Each entry names the version, the date, what was exercised, and what was not.

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

Not exercised: a live picture. `receivingFrames` stayed false for the whole
check, because the Cam Link 4K had no HDMI source attached at the time, and the
two Key Lights answered "the Internet connection appears to be offline" — the
desk was powered down. Neither says anything about this build; both need a
second look with the camera on. Frames in a consuming app are still unverified,
as in 0.4.1.

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
