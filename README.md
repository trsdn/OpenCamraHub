# OpenCamraHub

[![License](https://raw.githubusercontent.com/trsdn/OpenCamraHub/repo-stats/.github/badges-generated/license.svg)](LICENSE)
[![Minimum macOS version](https://raw.githubusercontent.com/trsdn/OpenCamraHub/repo-stats/.github/badges-generated/platform.svg)](#requirements)
[![CI](https://github.com/trsdn/OpenCamraHub/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/trsdn/OpenCamraHub/actions/workflows/ci.yml)
[![Latest release](https://raw.githubusercontent.com/trsdn/OpenCamraHub/repo-stats/.github/badges-generated/release.svg)](https://github.com/trsdn/OpenCamraHub/releases/latest)
[![Conformance](.github/badges/conformance.svg)](.github/conformance.yml)

A lightweight virtual camera for video calls. Point it at a camera, zoom into the
part of the frame that matters, and pick **OpenCamraHub** as your camera in Zoom,
Teams or Meet.

It does one job — framing a live camera — and deliberately does not record, does
not touch audio, and has no timeline, no projects and no accounts.

> **OpenCamraHub was called OpenLens until version 0.3.1.** Only the name changed. The
> app still installs as `OpenLens.app`, downloads are still named `OpenLens-*.dmg`,
> and the bundle identifiers are unchanged, so existing installs keep their scenes,
> their camera selection in conferencing apps, and their updates.

**Status:** actively developed and in daily use by its maintainer. Signed,
notarized builds are on the
[latest release](https://github.com/trsdn/OpenCamraHub/releases/latest) page, and
there is a [project page](https://trsdn.github.io/OpenCamraHub/) for readers who
want the product rather than the source. See
[Support and maintenance](#support-and-maintenance) for what to expect.

---

## Contents

- [What it does](#what-it-does)
- [Requirements](#requirements)
- [Install](#install)
- [How it works](#how-it-works)
- [Remote control](#remote-control)
- [Performance](#performance)
- [Build from source](#build-from-source)
- [Releasing](#releasing)
- [Metadata: what lives where](#metadata-what-lives-where)
- [Troubleshooting](#troubleshooting)
- [Privacy and your data](#privacy-and-your-data)
- [Language](#language)
- [Accessibility](#accessibility)
- [Support and maintenance](#support-and-maintenance)
- [Contributing](#contributing)
- [Repository stats](#repository-stats)
- [License](#license)

---

## What it does

- **Zoom and pan into any area of the frame.** Scroll or pinch over the picture
  to zoom around the pointer, drag to pan, double-click to reset. The inspector
  has a slider, an editable number field, a stepper and **⌘+ / ⌘− / ⌘0**, all moving in
  steps of 0.1×, if you would rather not aim with the mouse. The crop is a
  texture-coordinate remap inside a single Metal pass, so it costs nothing.
- **Sharp zoom.** Capture above 1080p and the crop still fills the 1080p output
  with real pixels — no upscaling. The inspector shows how far that reaches
  ("Stays sharp up to"), and the badge on the picture says `soft` once you pass
  it.
- **Scenes are the presets.** Camera, zoom, mirror and overlay are saved into
  the selected scene as you change them — there is no save button. Duplicate
  snapshots the current look, and **⌃⌥1…⌃⌥9** switch between scenes system-wide,
  so it works while you are in a call.
- **Pause without leaving the call.** **⌃⌥P** anywhere, or the button next to the
  scenes, blacks out the picture your call sees and hands the physical camera
  back, so its light goes out. The key lights the scene owns go out with it, so
  stepping away does not leave a lit, empty chair. The preview holds the last
  live frame, so you can see what you will resume into. The virtual camera keeps
  running throughout, so Teams or Zoom never see the device disappear.
- **Elgato Key Light control.** Lights are found on the network over Bonjour and
  driven from the app — on/off, brightness and colour temperature — so you do
  not reach for a phone mid-call. Each light can be marked as part of a scene:
  those follow scene changes and go dark when you pause, while a lamp lighting
  the rest of the room is left alone.
- **PNG overlay with alpha.** Drag it in the picture to move it, pull a corner
  to resize it, double-click to reset the size — or type exact percentages in
  the inspector and snap it to any of nine positions. The aspect ratio comes
  from the image, and it is composited in the same GPU pass.
- **Tone and colour correction** for cameras that have no controls of their own —
  HDMI grabbers like a Cam Link expose none, and macOS offers no manual values
  either. Exposure, black point, white point, midtones and an S-curve contrast,
  plus white balance on both axes — amber/blue and green/magenta — separate
  shadow and highlight tints, and saturation. Ten sliders that snap back to
  neutral in the middle, each with a field you can type an exact value into,
  folded into the render pass that already runs, so they cost nothing
  measurable.
- **Cheap.** Around 17 % of a single core — roughly 1.4 % of an M4 Pro — at
  1080p30 while a conferencing app is actually pulling frames. The capture
  session does not run at all when nobody is looking, and the preview pass is
  skipped when the window is hidden or the preview is switched off (**⌘P**),
  though on Apple silicon that pass is nearly free, so expect a fraction of a
  percent rather than a dramatic saving.

## Requirements

| | |
|---|---|
| **macOS** | 14.0 or later (Sonoma+) |
| **Architecture** | Apple Silicon (arm64) |
| **Install location** | `/Applications` — macOS will not activate a camera extension from anywhere else |
| **Lighting (optional)** | Elgato Key Light, Key Light Air or Key Light Mini on the same network |
| **Build tools** | Xcode 16 command-line tools, and [XcodeGen](https://github.com/yonaskolb/XcodeGen) if you change `project.yml` |

CI builds and tests on macOS 15 only. macOS 14 is supported, because that is
the deployment target, but it is not covered by an automated run.

## Install

Download the latest DMG from
**[Releases](https://github.com/trsdn/OpenCamraHub/releases/latest)**.

1. Open the DMG and drag the app to **Applications**.
2. Launch it and approve the camera extension in
   **System Settings › General › Login Items & Extensions**.
3. In your conferencing app, choose **OpenCamraHub** as the camera. Conferencing
   apps enumerate cameras at launch, so quit and reopen Zoom, Teams or Meet
   after installing.

Every release is signed with Developer ID, notarized by Apple and stapled, so it
runs without a Gatekeeper prompt. To check a download yourself:

```bash
spctl -a -vvv -t open --context context:primary-signature OpenLens-*.dmg
shasum -a 256 -c OpenLens-*.dmg.sha256
```

What this proves: the download is intact, and Apple notarized a build signed
with the maintainer's Developer ID. What it does not prove: that the build came
from a particular commit of this repository. The release's `provenance.json`
names the source commit the broker built, but it is the broker's own record,
not an independent attestation.

### Updates

OpenCamraHub checks GitHub Releases for a newer version once a day. When there
is one, a banner over the preview offers **Download**: open the disk image,
drag the app into **Applications** and replace the old copy. Your scenes and
settings stay. **OpenCamraHub › Check for Updates…** checks right away, and
**Check for Updates Automatically** in the same menu turns the daily check off.

The app does not install updates itself: it is sandboxed, and a sandboxed app
cannot replace itself in /Applications.

## How it works

```
OpenLens.app                          OpenLensCamera.systemextension
┌──────────────────────────┐          ┌──────────────────────────────┐
│ AVCaptureSession         │          │                              │
│   ↓ CVPixelBuffer        │          │                              │
│ Metal pass               │  sink    │  CMIOExtensionStream          │
│   crop + mirror + overlay│ ──────►  │    ↓                          │
│   ↓                      │  stream  │  "OpenCamraHub" camera        │
│ CAMetalLayer preview     │          │                              │
└──────────────────────────┘          └──────────────────────────────┘
                                                    ↓
                                          Zoom / Teams / Meet
```

The app never reads a pixel on the CPU. Camera buffers arrive IOSurface-backed,
are wrapped as Metal textures, rendered once, and the result is handed to the
camera extension through a CoreMediaIO **sink stream**. The extension republishes
it on the virtual camera device, and falls back to a placeholder card whenever the
app is not running.

## Remote control

OpenCamraHub can be driven from outside its window — by a script, by a Stream Deck,
or by an AI agent — through a control socket the app opens while it runs:

```
~/Library/Group Containers/G69Z5BNY97.com.trsdn.openlens/control.sock
```

The protocol is one JSON object per line. Send a command, get an answer:

```json
{"id": "1", "command": "scene.select", "params": {"index": 2}}
{"id": "1", "ok": true, "result": { ... }}
```

Subscribe with `events.subscribe` and the app pushes the state whenever it
changes, including changes made with the ⌃⌥1…⌃⌥9 hotkeys or in the app window, so
a hardware key can show what is actually happening rather than what it last
set.

Access control is the file's permissions. There is no port, no token, and
nothing listening on the network — which is also why the app needs no extra
entitlement to offer this.

[`Tools/openlens-mcp`](Tools/openlens-mcp) puts an **MCP server** in front of the
socket so an AI assistant can operate the camera, and doubles as a CLI:

```bash
node Tools/openlens-mcp/src/index.js call scene.next
node Tools/openlens-mcp/src/index.js watch
```

It has no dependencies. See its [README](Tools/openlens-mcp/README.md) for the
MCP client configuration and the full command list.

[`Tools/openlens-streamdeck`](Tools/openlens-streamdeck) is a **deck plugin** for
OpenDeck and the Elgato Stream Deck, so hardware keys can switch scenes, pause
the camera and drive key lights. Its keys follow the app rather than only
driving it: a scene key lights up while its scene is live, even when the scene
was changed with ⌃⌥3.

## Performance

Measured on an M4 Pro at 1080p30 with a Cam Link 4K, streaming to a real consumer,
as a percentage of **one** CPU core:

| | app | extension | total |
| --- | --- | --- | --- |
| Preview visible | 7.7 % | 3.6 % | **11.3 %** |
| Preview hidden | 6.3 % | 3.6 % | **9.9 %** |
| Paused | 0.8 % | 1.8 % | **2.6 %** |
| Nothing streaming | — | **0.0 %** | — |

Hiding the preview (inspector → Preview → Show preview) saves about 1.4 points.
It is worth switching off once a call is running, but it is not the main cost —
the virtual camera keeps streaming either way.

Pausing releases the physical camera whether or not the preview is showing,
which takes `UVCAssistant` from around 28 % to **0.0 %** — that process is not
counted in the table above, but it is the single largest consumer while a
camera is open.

Four findings worth recording, because all four were counter-intuitive:

- The extension used to burn **a third of a core doing nothing**.
  `CMIOExtensionStream.consumeSampleBuffer(from:)` does *not* block on an empty
  sink queue — it calls back immediately with a `nil` buffer. Re-arming from the
  completion handler, which is the shape Apple's sample code suggests, is therefore
  a busy loop. Successful reads now re-arm immediately, empty reads back off 4 ms.
  This alone took the total from 52 % to 11 % and cost no frames: still exactly
  30.00 fps.
- Sending **NV12 instead of BGRA** moves 62 % fewer bytes per frame and measured as
  **zero** improvement. It is kept because it is the format the rest of the stack
  wants, but it is not why this is fast. CoreMediaIO hands consumers `2vuy`
  regardless of what we send.
- The sink stream used to be opened as soon as the device was found and held for
  the whole life of the app, to pin the extension process and dodge stale object
  IDs. A *started* CoreMediaIO stream is not free: the 4 ms empty-read backoff
  above still means 250 wakeups a second, and CoreMediaIO does per-second
  bookkeeping for every running stream — visible as a steady 1 Hz tick under
  `log show --predicate 'subsystem == "com.apple.cmio"'`. That was **3–6 % of a
  core, around the clock, with nothing streaming**. The sink now opens when a
  consumer actually starts the camera and is released five seconds after it
  stops; the delay is what keeps a camera switch mid-call from paying for a fresh
  stream start. Idle extension cost is now **0.0 %**.
- **Colour tags are not free metadata, and the one that hurts is not ours to
  drop.** Under `sample`, 25 of 56 stacks on the receiving
  `CMIOExtensionProviderHostContext` queue sat inside
  `CGColorSpaceCreateWithICCData` — roughly **45 % of the work on that queue**
  spent validating a profile and building a tone-reproduction-curve LUT from
  scratch, once per frame, for a colour space that never changes. CoreMedia
  serialises a buffer's colour attachments with every sample and faithfully
  reconstructs a `CGColorSpace` from them in
  `CMIOExtensionSample.init(xpcDictionary:)` rather than caching by profile
  identity. On the **inbound** leg that is Apple's code on both ends: the sender
  is the camera's own extension (a Cam Link 4K hosted by `UVCAssistant`), the
  rebuild finishes before `captureOutput(_:didOutput:from:)` ever sees a buffer,
  and `AVCaptureVideoDataOutput.videoSettings` chooses pixel format and size but
  cannot decline an attachment. There is no hook — **not addressable from our
  side.** The **outbound** leg is ours, and it is the same cost inflicted on
  whatever conferencing app is watching, so the frames we publish tag only
  `kCVImageBufferYCbCrMatrixKey`: a consumer needs the matrix to decode the two
  planes and getting it wrong is visible, while primaries and transfer function
  are display characteristics every consumer assumes to be 709/sRGB anyway — and
  tagging them is exactly what makes CoreMedia synthesise the profile that the
  consumer then rebuilds thirty times a second. `VideoRendererTests` pins that on
  both buffers we send, the rendered frame and the black pause frame, because
  adding a well-meant tag back is a one-line regression that costs someone else's
  CPU and nothing here would notice.

The lesson every time: measure the states, don't trust the theory. `ps %cpu` is a
lifetime average and will hide all of this — diff `ps -o time=` over a fixed window
instead.

### Capture quality: sharpness costs frames, not CPU

"Up to 4K" is worth it if you zoom. Cropping a 4K frame to 1.4× and scaling it into a
1080p output measured **1.63× more fine detail** than doing the same crop on a 1080p
source, and 2.06× more energy at half the Nyquist frequency. It is real, but it is
subtle: visible on edges and texture, not a different picture.

The catch is bandwidth, not processing. Uncompressed 4K 4:2:0 at 30 fps is ~373 MB/s,
which a USB 3 capture device cannot carry. A Cam Link 4K therefore delivers about
**20 fps** at 4K against a solid 30 fps at 1080p — sharper stills, choppier motion.
Both 4K formats it advertises behave the same way, so this is the link, not the format
choice. The inspector shows a live "Receiving" readout of what actually arrives, which
is the only honest way to make that call on an unknown camera.

Three AVFoundation traps sit between asking for 4K and getting it, all found the hard way:

- `device.activeFormat` is **outranked by the session preset**. With the default `.high`
  a 4K device still hands back 1080p. macOS has no `.inputPriority`, so a size-specific
  preset like `.hd4K3840x2160` has to be set, and the video output has to be attached
  *before* it or the session renegotiates straight back to 1080p.
- `output.videoSettings` naming a pixel format **without** `kCVPixelBufferWidthKey` and
  `HeightKey` silently inserts a scaler that returns 1080p — whatever the preset and
  `activeFormat` say. This one is invisible: nothing logs, nothing fails.
- Frame rate ranges are **never round numbers** (a Cam Link reports 30.00003 and
  60.00024), the **first** range is the fastest one, and a rate pinned inside
  `beginConfiguration`/`commitConfiguration` is wiped when the preset is committed.
  Pinning has to happen again *after* `startRunning()`, clamped into the range the
  device actually published. Missing this ran "1080p" at 60 fps, which made the
  supposedly cheap mode cost **13.2 %** of a core against 4K's 5 %; pinned properly it
  is 8 %, and the capture path alone drops from 4.3 % to 1.3 %.

### Colour correction is free

Exposure, levels, contrast, white balance, tint, split tinting and saturation happen inside the
fragment shader that already runs, so they cost no extra pass, no extra buffer and no extra
CPU work. Measured
over two 60-second windows at 1080p30 with the preview visible: **7.52 %** and **7.63 %**
of one core, against **7.97 %** for the same build without the colour code — a difference
inside the noise.

The shader is deliberately **branchless**: the coefficients are computed once on the CPU
when a slider moves, and the per-pixel maths runs identically whether the sliders sit at
neutral or at their extremes. There is no "off" fast path to fall back to, which also
means neutral settings are already the worst case for measurement.

This is why the correction lives here at all. A Cam Link is an HDMI grabber, not a camera —
it exposes no exposure or white-balance controls, and macOS `AVCaptureDevice` offers no
manual values on macOS either. The render pass is the only place left, and it happens to
be the cheapest one.

## Build from source

```bash
brew install xcodegen
./scripts/build.sh          # builds, signs and installs to /Applications
```

During development, allow unnotarized extensions once per machine:

```bash
systemextensionsctl developer on
systemextensionsctl list                 # check activation state
```

macOS only re-stages an extension when its version changes, so `build.sh` stamps
every build with a timestamped build number. Quit and relaunch the app after
installing — replacing the extension underneath a running app drops the frame
transport.

### The app icon

`Sources/OpenLens/AppIcon.icns` is generated, not hand-drawn. Regenerate it after
editing the artwork:

```bash
swift scripts/make-icon.swift
```

Two macOS 26 quirks are baked into that script, both found the hard way:

- **No asset catalog.** `actool` always writes `CFBundleIconName` into the merged
  `Info.plist`, and on macOS 26 that key routes icon lookup through the new icon
  pipeline, where a classic `AppIcon.appiconset` is replaced by Apple's grey
  "icon design template" placeholder. The app then ships with no icon at all.
  A plain `.icns` referenced by `CFBundleIconFile` renders correctly on 14–26.
- **No 1024 px slice.** An `ic10` entry makes macOS 26 treat the icon as legacy
  artwork and shrink it onto a light grey plate instead of masking it edge to
  edge like every other app. The largest slice is therefore 512 px.

If the icon still looks like a pale blue grid after installing, that is a stale
entry in the system icon cache, keyed by bundle path. Reboot, or:

```bash
sudo rm -rf /Library/Caches/com.apple.iconservices.store && killall Dock
```

Tests, including GPU tests that read back the rendered output and assert the crop
and overlay compositing:

```bash
xcodebuild test -project OpenLens.xcodeproj -scheme OpenLens \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
```

Release build (notarized, stapled DMG): see [Releasing](#releasing) below — it
does not happen on this machine.

## Releasing

Releases are built, signed, notarized and stapled by
**[trsdn/macos-notarization-broker](https://github.com/trsdn/macos-notarization-broker)**,
a manual GitHub Actions workflow. Apple credentials live only in that
repository's signing environment; nothing here holds them, and no step of a
release runs locally. The release notes are the `CHANGELOG.md` entry for the
version, and the broker refuses to publish without one.

The procedure, the artifact names and the constraints they put on this
repository — why `OpenLens.xcodeproj` is committed, and what needs a broker
change first — are in
**[AGENTS.md](AGENTS.md#releases-are-notarized-by-the-broker-never-locally)**,
so there is one description rather than two that drift. Each release is
installed from its published artifact and launched; the dated results are in
[docs/release-smoke-tests.md](docs/release-smoke-tests.md).

## Metadata: what lives where

| Property | Authority | Also appears in |
| --- | --- | --- |
| Version | `project.yml` (`MARKETING_VERSION`) | The bundle, the release tag, the release badge |
| Minimum macOS | `project.yml` (`deploymentTarget`) | The bundle, the platform badge, Requirements above |
| Bundle name and identifiers | `Sources/OpenLens/Info.plist`, `project.yml` | The broker profile, which must agree |
| Display name | `en.lproj/InfoPlist.strings` (see [AGENTS.md](AGENTS.md)) | Finder, the Dock, the menu bar |
| Description | `Info.plist` (`OCHDescription`) | This README, the repository description, the project page |
| License | `LICENSE`, mirrored in `Info.plist` (`OCHLicenseIdentifier`, `NSHumanReadableCopyright`) | The license badge |
| Repository and issue tracker | `Info.plist` (`OCHRepositoryURL`, `OCHIssueTrackerURL`) | The Help menu |

`scripts/badges.py` renders the license, platform and release badges from
those authorities, and `AppDisplayNameTests` fails when the bundle's copies
drift from them.

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| The camera never appears in Zoom | The extension is not approved yet, or the app was launched from outside `/Applications`. Conferencing apps also enumerate cameras **at launch** — quit and reopen Zoom/Teams/Meet after installing. |
| Picked OpenCamraHub, but the app shows no picture | Selecting a camera in a settings menu does not open it. Start a call or open the app's device preview and switch video on; the app's banner turns green the moment a consumer attaches. |
| "Lost contact with the camera extension" | The extension was replaced while the app was running (an update does this). That kills the app's CoreMediaIO client state for good, so the banner offers a **Restart OpenCamraHub** button; a fresh process reconnects instantly. |
| "Camera is in use" | Some UVC devices (Cam Link 4K among them) refuse concurrent access. Quit OBS or any other app holding the camera. |
| A static card instead of the picture | The app is not running. The extension keeps the device alive on its own so calls do not break. |
| Zoom looks soft | You are past the "Stays sharp up to" limit in the inspector, and the badge says `soft`. Raise **Capture quality**. |

## Privacy and your data

OpenCamraHub collects nothing. There is no account, no analytics, no telemetry
and no crash reporting. The picture never leaves your Mac except through the
conferencing app you choose it in.

It opens two kinds of network connection:

- **Once a day, the update check** asks the GitHub Releases API whether a newer
  version exists. The request carries no identifier. Turn off
  **Check for Updates Automatically** and nothing is contacted unless you choose
  **Check for Updates…** yourself.
- **Elgato Key Lights on your local network**, found over Bonjour and driven over
  their local HTTP API. Nothing about them leaves your network.

**What is stored, and where.** Everything the app remembers is in one
preferences file inside its sandbox container:

```
~/Library/Containers/com.trsdn.openlens/Data/Library/Preferences/com.trsdn.openlens.plist
```

It holds your scenes, the selected scene, the lights the app has found or you
added, which inspector sections are open, and the update setting. An overlay
image is not copied: the app keeps a bookmark to the file wherever you keep it.
If saved scenes ever cannot be read, the app copies them to
`scenes.v1.unreadable` in the same preferences before anything else happens.

**How long, and how to remove it.** It is kept until you delete it. Removing the
app does not remove it, so an update or reinstall keeps your scenes. To export
it, copy the file above. To delete everything, quit the app and move
`~/Library/Containers/com.trsdn.openlens` to the Trash.

## Language

**English only.** English is the interface language and the language of every
document, commit and issue here. There are no other localizations. The one
`en.lproj` in the bundle exists only to show the app's name as OpenCamraHub in
Finder (see AGENTS.md), not to translate anything.

## Accessibility

What works:

- **Every action has a keyboard route.** Scenes switch with ⌃⌥1…⌃⌥9 from any
  app and pause with ⌃⌥P. Zoom (⌘+, ⌘−, ⌘0), the preview (⌘P) and the scene
  commands are menu items, so they are reachable from the keyboard like any
  menu. Tone, colour and zoom values each have a number field you can type an
  exact value into.
- **Controls carry names.** The inspector's fields and sliders expose their
  names to VoiceOver ("Exposure value", "Exposure", "Studio links brightness"),
  the light sliders also speak their value, and the collapsible sections can be
  opened through accessibility.

Known limitations, stated rather than left implicit:

- **Placing the zoom and the overlay by dragging is pointer-only.** The keyboard
  equivalents are the zoom shortcuts and the overlay's percentage fields and
  nine snap positions, which reach every placement the pointer can.
- **The Key Light brightness and temperature sliders have no number field**, so
  an exact value is set by dragging or with the arrow keys rather than typed.
- **No systematic keyboard or VoiceOver audit on a running build has been
  recorded.** The keyboard routes above were reviewed in the source and spot
  checked; focus order and the focus indicator have not been walked end to end.

## Support and maintenance

Maintained by [@trsdn](https://github.com/trsdn) as a single-maintainer project,
best-effort and in the open. There is no service-level commitment and no
guaranteed response time.

- **Bugs and proposals** → [issues](https://github.com/trsdn/OpenCamraHub/issues),
  which offer a form for each.
- **Security vulnerabilities** → report privately through
  [a security advisory](https://github.com/trsdn/OpenCamraHub/security/advisories/new),
  not a public issue. See [SECURITY.md](SECURITY.md).
- **Why the code is shaped the way it is** → [AGENTS.md](AGENTS.md), which
  records the design constraints and the traps that produced them.

## Contributing

Issues and pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md)
for how to build, test and structure a change, and
[SECURITY.md](SECURITY.md) for reporting a vulnerability privately.

## Repository stats

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/trsdn/OpenCamraHub/repo-stats/.github/stats/repo-card-dark.svg">
  <img alt="Repository statistics" src="https://raw.githubusercontent.com/trsdn/OpenCamraHub/repo-stats/.github/stats/repo-card.svg">
</picture>

Generated daily by the [shared stats workflow](https://github.com/trsdn/.github/blob/main/docs/repo-stats.md)
into the `repo-stats` branch, together with the license, platform and release
badges above, so neither is committed to master by hand or by a bot.

## License

MIT — see [LICENSE](LICENSE).
