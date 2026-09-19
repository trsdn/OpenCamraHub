# Working on OpenCamraHub (formerly OpenLens)

OpenCamraHub is a macOS virtual camera: it captures a real camera, crops,
corrects and composites it in one Metal pass, and publishes the result through
a CoreMediaIO camera extension that Teams, Zoom and Meet can select. It also
drives Elgato Key Lights and is remote-controllable over a local socket.

## Layout

| Path | What it is |
| --- | --- |
| `Sources/OpenLens` | The app: capture, rendering, scenes, lighting, updates, UI |
| `Sources/OpenLensCamera` | The camera system extension |
| `Sources/OpenLensShared` | Identifiers and types both processes share |
| `Tests/OpenLensTests` | Unit and rendering tests; the test target compiles app sources directly (see `project.yml`) |
| `Tools/openlens-streamdeck` | The OpenDeck / Stream Deck plugin (Node, no dependencies) |
| `Tools/openlens-mcp` | The MCP server and socket client the plugin vendors |
| `site/`, `scripts/build_site.sh` | The GitHub Pages site |
| `project.yml` → `OpenLens.xcodeproj` | XcodeGen spec and the committed project generated from it |

Authoritative commands:

```bash
xcodebuild test -project OpenLens.xcodeproj -scheme OpenLens -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
(cd Tools/openlens-streamdeck && npm test)
xcodegen generate   # after changing project.yml; commit the result
```

## Forbidden and high-risk operations

- **No force pushes, no history rewriting, no deleting `master`.** The branch
  ruleset refuses all three, and `master` only changes through a pull request
  whose CI passes. Release commits go through a pull request too. Never ask
  for a bypass.
- **Never move or re-point a published release tag.** A tag that already has a
  GitHub release is what installed copies and the broker's provenance refer to;
  cut a new patch version instead.
- **No credentials in the repository.** Apple credentials exist only in the
  notarization broker; do not create an app-specific password or a `notarytool`
  profile here (see below). Secret scanning with push protection is on.
- **Releases only through the broker**, as described below, and only after the
  changelog entry for the version exists.
- **Never delete or overwrite the user's scenes.** The sandbox container
  `~/Library/Containers/com.trsdn.openlens` holds them; do not remove it or its
  preferences to "reset" a test. Use a debug build, which writes elsewhere (see
  the last section), and copy the preferences aside first if a test must touch
  them.

## The name changed; the identity did not

The app is called **OpenCamraHub** wherever a person reads it: Finder,
Launchpad, Spotlight, the Dock and the menu bar, the virtual camera that
conferencing apps list (`OpenLensID.deviceName`), the window, banners and
prompts, the deck plugin's name, and the docs.

The Finder name is the subtle one. `Info.plist` keeps
`CFBundleDisplayName = OpenLens` with `LSHasLocalizedDisplayName`, and the new
name comes from `Sources/OpenLens/en.lproj/InfoPlist.strings`. macOS only shows
a localized name when the unlocalized one equals the bundle folder's name;
putting OpenCamraHub straight into `Info.plist` makes Finder, Launchpad and
Spotlight fall back to "OpenLens". `AppDisplayNameTests` pins this.

Everything that something else matches on keeps the old name, deliberately:

| Keeps `OpenLens` | Because |
| --- | --- |
| `OpenLens.app`, executable `OpenLens` (`PRODUCT_NAME`) | The broker profile declares both |
| `com.trsdn.openlens*` bundle ids, app group, `control.sock` | Scenes live in the sandbox container, and code signing, the extension and the deck plugin are keyed on them |
| `OpenLens-<version>.dmg` release asset | Copies from 0.3.0–0.4.0 still use AppUpdater, which looks for exactly that name in `trsdn/OpenLens` |
| The camera's device UID and stream names | Teams and Zoom remember the camera by UID; the app finds its extension's sink stream by name |
| `OpenLens.xcodeproj`, scheme, targets, `Sources/OpenLens*` | The broker's `openlens-xcode` adapter builds that project and scheme |
| Deck action UUIDs `com.trsdn.openlens.*`, MCP tool names `openlens_*` | Saved deck profiles and MCP configs reference them |

Two rules follow:

- **Never create a new repository called `trsdn/OpenLens`.** The GitHub
  repository was renamed, and installed copies still ask the API for
  `trsdn/OpenLens`; that works only through GitHub's rename redirect, which a
  new repository of that name would take over.
- The broker checks `Info.plist`'s `CFBundleDisplayName` against the
  profile's `bundle_display_name`, which is therefore `OpenLens` as well.
  Change one only together with the other.

## Releases are notarized by the broker, never locally

**Do not run `xcrun notarytool`, do not ask for an app-specific password, and do
not suggest creating a `notarytool` keychain profile.** Apple credentials
deliberately do not exist on this machine.

Notarization goes through **[trsdn/macos-notarization-broker](https://github.com/trsdn/macos-notarization-broker)**,
a manual GitHub Actions workflow that builds, signs, notarizes and staples in
isolated jobs so that source-repository code never touches the signing secrets.

To cut a release:

1. In a pull request: move the `## [Unreleased]` entries under a new
   `## [X.Y.Z] - YYYY-MM-DD` heading in `CHANGELOG.md`, bump `MARKETING_VERSION`
   and `CURRENT_PROJECT_VERSION` in `project.yml`, regenerate the project, and
   merge once CI passes. `master` accepts no direct pushes.
2. Tag the merged commit on `master` as `vX.Y.Z` and push the tag.
3. From a clean checkout of the broker's `main`:
   `scripts/request.sh openlens vX.Y.Z --publish`.
4. Download the published release, install it into `/Applications`, launch it,
   and add a dated entry to `docs/release-smoke-tests.md`.

`request.sh` correlates the exact run, downloads only that artifact, and
verifies `provenance.json` plus the release digests. `--publish` then creates
the release with the changelog entry as its notes, and refuses if that entry is
missing or empty or anything is still under Unreleased; then it uploads the
verified files. Dispatching the workflow from the Actions tab skips that step,
so the release would miss its files and notes.

### OpenLens is allowlisted as the `openlens` profile

The broker only signs applications listed in its `profiles/apps.json`. OpenLens
was added there in
[broker#25](https://github.com/trsdn/macos-notarization-broker/pull/25), which
declares:

- the bundle identifier `com.trsdn.openlens`, the executable, `arm64`, and the
  minimum system version;
- a `nested_executables` entry for the camera system extension
  `Contents/Library/SystemExtensions/com.trsdn.openlens.camera.systemextension`,
  pinned as a `plugin_bundle` with package type `SYSX` — anything Mach-O or any
  nested bundle that is not declared is rejected by the preflight;
- broker-owned entitlements plists for both the app and the extension;
- the `openlens-xcode` build adapter, because the broker never runs scripts from
  the source repository.

Since
[broker#29](https://github.com/trsdn/macos-notarization-broker/pull/29) it also
declares a `provisioning_profile`. `com.apple.developer.system-extension.install`
is a *restricted* entitlement: macOS honours it only if the app bundle contains
`Contents/embedded.provisionprofile` granting it. Nothing about signing reveals
a missing profile — codesign, notarization, stapling and Gatekeeper all pass,
and the app dies at launch with `Launch failed` and, in the log,
`AppleMobileFileIntegrityError -413`. Releases v0.1.0 and v0.1.1 shipped that
way and cannot be started on any Mac.

The profile lives in the broker repository as
`profiles/provisioning/openlens.provisionprofile`
([broker#35](https://github.com/trsdn/macos-notarization-broker/pull/35)). It is
a **Mac Team Direct** profile with `ProvisionsAllDevices = true`, which Xcode
issues on export with `-allowProvisioningUpdates`; the broker refuses anything
else. The Xcode "Mac Team Provisioning Profile" that a local build embeds names
the Macs it was issued for, so it works on the machine that built the app and
nowhere else. A profile is not a secret — a copy ships inside every downloaded
app that uses one — so it belongs in the repository rather than in an
environment secret.

## The broker builds unsigned, so team build settings expand to nothing

The broker builds the source in a job with no Apple credentials and signs
afterwards. `$(TeamIdentifierPrefix)` is therefore empty in every file the build
substitutes, while a local Xcode build fills it in and looks fine.

That difference cost a release. `Sources/OpenLensCamera/Info.plist` spelled the
camera extension's `CMIOExtensionMachServiceName` as
`$(TeamIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)`, so the broker's build
named it `com.trsdn.openlens.camera` instead of
`G69Z5BNY97.com.trsdn.openlens.camera`. A sandboxed system extension whose mach
service name is not inside one of its app groups is rejected by `sysextd`, which
uninstalls it seconds after activation:

```
System extension com.trsdn.openlens.camera has an invalid mach service name or
is not signed, the value must be prefixed with one of the App Groups in the
entitlement.
```

The app shows only `extension category returned error`. Nothing else fails: the
app launches, signature, notarization and Gatekeeper all pass. Confirm with

```bash
log show --last 10m --predicate 'process == "sysextd"' --style compact | grep openlens
```

Prefer literal team identifiers over build settings anywhere the broker's
unsigned build reads them. `CameraExtensionInfoPlistTests` pins this one.

Any change to the app's identity, layout, architecture, entitlements, or minimum
macOS version needs a reviewed pull request against the broker **before** the
next release, or the preflight will reject the build.

Two consequences for this repository:

- `OpenLens.xcodeproj` is committed on purpose. The broker's build job uses only
  the preinstalled runner toolchain, so it cannot fetch `xcodegen`. Regenerate
  **and commit** the project after changing `project.yml`.
- The source repository must stay readable by the broker workflow, which
  authenticates with its own `github.token`.

`scripts/release.sh` in this repository predates the broker. It still describes
the local path and is kept only for reference.

## Why notarization is not optional here

Gatekeeper refuses to activate a camera system extension that is not notarized,
so there is no "just ship the zip" shortcut. The app and the embedded extension
are signed separately, and both must carry a Developer ID Application
certificate.

A notarized build is not necessarily a working one. Before publishing a release,
download the artifact and actually start it — the local development build is
signed differently and proves nothing about it:

```bash
ls OpenLens.app/Contents/embedded.provisionprofile   # must exist
spctl -a -vvv -t exec OpenLens.app                   # must say "accepted"
open OpenLens.app                                    # must actually open
```

## Updates are offered, not installed

The app is sandboxed, and a sandboxed app may neither mount a disk image nor
replace itself in /Applications. The in-app installer it used to have
(AppUpdater) failed at exactly that step (#41), so it was removed.

`UpdateManager` now only checks
`api.github.com/repos/trsdn/OpenCamraHub/releases/latest` once a day and on
**Check for Updates…**, and `ReleaseCheck` decides from the response. When a
newer version exists, the banner offers **Download**, which opens
`OpenLens-vX.Y.Z-macOS-arm64.dmg` in the browser, and says how to install it:
open the disk image and drag the app over the old copy. Settings and scenes
survive that, because they belong to the bundle identifier. If a release lacks
that disk image, **Download** falls back to the release page.

Copies from 0.3.0 to 0.4.0 still carry AppUpdater. They look for
`OpenLens-<version>.dmg` in `trsdn/OpenLens` (reached through the rename
redirect), find the release, and then fail to install it. That is accepted:
those users update by hand once, and keep the download-based flow from then on.
The broker still publishes `OpenLens-<version>.dmg` for them.

## Build and test

```bash
xcodebuild test -project OpenLens.xcodeproj -scheme OpenLens -destination 'platform=macOS'
```

The Xcode project is generated from `project.yml` by `xcodegen`; regenerate it
after adding or removing files.

## Frames we publish tag only the YCbCr matrix

Colour attachments travel with a sample, and the receiving side rebuilds a
`CGColorSpace` from them — `CGColorSpaceCreateWithICCData`, profile validation
plus a fresh gamma LUT — inside `CMIOExtensionSample.init(xpcDictionary:)`, once
per frame. On the inbound leg from a physical camera that was 45 % of the work on
the receiving queue, and it is Apple's code on both ends, so there is nothing to
hook. The outbound leg is ours: `VideoRenderer` sets `kCVImageBufferYCbCrMatrixKey`
and nothing else, because a consumer needs the matrix to decode the two planes
while primaries and transfer function only make CoreMedia synthesise a profile
for it to rebuild thirty times a second.

Adding a colour tag "for correctness" therefore costs someone else's CPU and
nothing here would notice. `VideoRendererTests` pins both buffers we send.

## The scene format is hand-written

`CameraScene` has a `CodingKeys` list, a spelled-out initialiser and two private
optional properties. Adding a property and forgetting any of the three compiles
cleanly and silently drops the value from every saved scene.
`CameraSceneCodingTests.testTheStoredKeysAreExactlyTheOnesWeExpect` pins the key
set so that mistake fails a test instead of a user's presets.

Whatever sets the new property in `AppModel` must also persist it — either
`scenes.save()` directly, or `schedulePersist()` for anything driven by a slider.

## Scenes that cannot be read are never overwritten

`SceneStore.load` reports a decoding failure as `readability == .unreadable`
instead of swallowing it, copies the bytes to `scenes.v1.unreadable`, and `save`
refuses to write for as long as that lasts. `AppModel` correspondingly only
creates a starter scene when nothing was ever saved.

Together these close a total data-loss path: a scene the app could not decode
used to leave `scenes` empty, which made `AppModel` create a blank scene and
save it over the user's entire library on launch. `SceneStorePreservationTests`
pins all of it — do not relax the guard in `save` to "simplify" it.

Discarding the data stays possible, but only through `startFresh()`, which the
user triggers from `SceneRecoveryBanner`. Nothing may discard scenes on the
user's behalf.

## The app is sandboxed, so debug builds write somewhere else

Preferences live in
`~/Library/Containers/com.trsdn.openlens/Data/Library/Preferences/`. A build made
with `CODE_SIGNING_ALLOWED=NO` has no sandbox entitlement and uses
`~/Library/Preferences/` instead, where it looks like an app with no saved
scenes. Check the container before concluding anything about missing settings.
