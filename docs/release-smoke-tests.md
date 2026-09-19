# Release smoke tests

Every release is installed from its **published** artifact, the way a user gets
it, and launched before it counts as done. A notarized build is not necessarily
a working one: releases 0.1.0 and 0.1.1 passed every signing check and could not
be started at all (see AGENTS.md).

Each entry names the version, the date, what was exercised, and what was not.

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
