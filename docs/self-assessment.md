# Self-assessment: trsdn/OpenCamraHub

- Standard: trsdn Repository Quality Standard **1.15.0**
- Assessed on: 2026-09-20, at `master` (`673cb14`, clean and in sync), after the 0.4.1 release
- State: **Healthy** — no criterion is `Fail`; `Partial` results do not lower the state
  ([Overall State](https://github.com/trsdn/.github/blob/v1.15.0/docs/repository-quality-standard.md#overall-state))
- Record: `.github/conformance.yml`
- Previous assessment: 1.13.0 on 2026-09-19 (76 pass, 5 partial, 1 fail, 22 n/a). What changed and why is in the delta section at the end.
- Method: `scripts/assess.py --repo trsdn/OpenCamraHub` (v1.15.0) decided 19 criteria from facts it could read. Every other criterion was decided by this assessing agent from the repository at `master` and read-only `gh api` calls, under
  [Deciding Without The Maintainer](https://github.com/trsdn/.github/blob/v1.15.0/docs/repository-quality-standard.md#deciding-without-the-maintainer),
  by the rule text (decision 0011). No question was left to the maintainer, and no result is `unknown`.

## Profiles

| Profile | Applies | Why |
|---|---|---|
| Public | Yes | Public repository |
| Software | Yes | Swift app, camera extension, Node tools |
| Deployable | No | The repository operates no deployment; the site is static GitHub Pages, which 1.15.0 states is not Deployable |
| Package | Yes | Notarized DMG and ZIP release artifacts |
| Product Identity | Yes | An installed application |
| Documentation | No | The primary product is software, not documentation |
| Published Site | Yes | `trsdn.github.io/OpenCamraHub/` is published from `site/` |
| Archived | No | Active |

## Result summary

104 criteria: **82 pass, 0 partial, 0 fail, 22 n/a**.

Every gap this assessment found was closed rather than recorded: the Key Light
sliders got accessibility labels and values (`X02`), a committed
`swift-format` configuration is enforced by a CI job (`S03`), CI gained a
`macos-latest` job beside the pinned `macos-15` one (`S04`), the release
procedure now has one home with the other linking to it (`B13`), and the
bundle carries a description alongside a README table naming the authority
for every metadata property (`R01`).

State **Healthy**: no criterion is `Fail`, and 1.15.0 states that `Partial` and
`N/A` results, including intended ones, do not lower the state. No critical
criterion (`B04`, `D01`–`D04`, `D06`) is failing: no committed secret, no
deployment, no unrecoverable state.

No `Partial` results remain.

## Readings this assessment applied

Stated because a later reader cannot check a result against a threshold they
cannot see ([Judgement words](https://github.com/trsdn/.github/blob/v1.15.0/docs/repository-quality-standard.md#deciding-without-the-maintainer)):

- **`X01`/`X02`/`X03` are decided from source**, as 1.15.0's evidence column allows. The agent read `Sources/OpenLens/UI/` and `OpenLensApp.swift` for gesture-only interactions, custom controls, suppressed focus, and accessibility labels. The product was not operated.
- **"Newest version available to the runner" (`S04`)** is read as the newest macOS runner image GitHub offers, not the newest image the repository happens to pin. `macos-15` is pinned, and a `macos-latest` job would settle the range claim; until then the claim "macOS 14 or later" is not demonstrably covered at its top end.
- **"Materially supported" (`S04`)** is read as the platforms the README's Requirements table claims.
- **A smoke record (`R05`)** counts under the "no kit exists, but a dated record names the version installed and launched by hand and what was exercised" row; the record also names what it does not cover.

## Per-criterion evidence

### Baseline

| ID | Result | Evidence / fix |
|---|---|---|
| B01 | pass | Name "OpenCamraHub" plus a description stating the purpose (GitHub metadata) |
| B02 | pass | `README.md` states purpose, audience, a **Status** line, install and usage, and key links |
| B03 | pass | `LICENSE`, MIT, detected by GitHub (script) |
| B04 | pass | `.gitignore` ignores `.build/`, `xcuserdata/` and the generated plugin `vendor/`; no credential file or token-shaped string is tracked. The generated `.xcodeproj` is committed deliberately, with the regenerating command documented, which 1.15.0 counts as maintained source |
| B05 | pass | README "Build from source", `AGENTS.md` and `.github/github-app.yml` document `xcodebuild test -project OpenLens.xcodeproj -scheme OpenLens …`; it ran successfully locally (193 tests) and the latest `ci.yml` run on `master` is green |
| B06 | pass | Two parts, both met: squash is the only allowed merge method (repository settings and the ruleset's `allowed_merge_methods`) and the ruleset requires a pull request; open critical alerts are zero (`dependabot/alerts?state=open&severity=critical` → 0, `secret-scanning/alerts?state=open` → 0, code scanning has no analysis and contributes none) |
| B07 | pass | README Requirements: macOS 14, arm64, Xcode 16; `project.yml` holds the deployment target; the plugin needs Node 20 (`install.sh`) |
| B08 | pass | `CHANGELOG.md` (Keep a Changelog) has an entry for the latest release 0.4.1, plus GitHub releases and linked issues |
| B09 | pass | Public, 13 topics, homepage `https://trsdn.github.io/OpenCamraHub/`, not archived — each agreeing with the README |
| B10 | pass | `.github/CODEOWNERS` (`* @trsdn`) names the owner and `README.md` → Support and maintenance states the maintenance status |
| B11 | pass | `.github/conformance.yml` committed and validated by `.github/workflows/conformance.yml`; `assessed_on` is today (script) |
| B12 | pass | `trsdn-standard` topic set (script) |
| B13 | pass | The release procedure lives in `AGENTS.md`; `README.md` → Releasing keeps a short summary and links to it. The deep-dive measurements stay in the README where a reader of the product looks for them |
| B14 | na | The repository holds and references no credential: workflows use only `GITHUB_TOKEN`. `SECURITY.md` → Credentials names the Apple credentials that live in the broker and who replaces them |
| B15 | na | Nothing third-party is redistributed: since #42 the app has no package dependencies, and the plugin's `vendor/` is a copy of this repository's own `openlens-mcp` client |
| B16 | pass | Ruleset *Protect master* (active, no bypass actors) blocks deletion and non-fast-forward pushes (script) |

### Public

| ID | Result | Evidence / fix |
|---|---|---|
| P01 | pass | MIT, OSI-approved, SPDX detected by GitHub (script) |
| P02 | pass | `CONTRIBUTING.md` and `CODE_OF_CONDUCT.md` recognized (script) |
| P03 | pass | Private vulnerability reporting enabled and `SECURITY.md` published (script); the issue chooser links to the advisory route |
| P04 | pass | Issue forms and a PR template present (script) |
| P05 | pass | README covers install, configuration, examples, compatibility (Requirements), security (links `SECURITY.md`) and support status |
| P06 | pass | Community profile complete (script) |
| P07 | pass | Non-empty description, 13 topics, and a homepage that resolves (HTTP 200) |
| P08 | pass | Badge block in the required order: license, platform, CI, latest release, conformance. License, platform and release are generated by `scripts/badges.py` from `Info.plist`, `project.yml` and git tags into the `repo-stats` branch; CI is GitHub's first-party workflow badge; conformance is generated from the record |
| P09 | pass | `stats.yml` regenerates the card on a schedule and on release into the `repo-stats` branch, and the README selects it with `<picture>`; the card is produced by a workflow, not committed by hand |
| P10 | pass | The bug form asks what happened, expected versus actual, steps, app version, macOS and Mac model, camera and consumer app; blank issues are disabled |
| P11 | pass | `.github/PULL_REQUEST_TEMPLATE.md` asks what and why, the linked issue, **Risk**, and validation |

### Software

| ID | Result | Evidence / fix |
|---|---|---|
| S01 | pass | No third-party dependencies; the generated project is committed and its regenerating command documented; `xcodebuild` commands documented |
| S02 | pass | 193 XCTest cases run in `ci.yml` and locally. Failure paths are asserted (`ReleaseCheckTests` rejects drafts, pre-releases and unreadable JSON; `ControlProtocolTests` rejects out-of-range numbers; `SceneStorePreservationTests` covers unreadable scenes), and the main entry point — the render and publish path — is exercised by `VideoRendererTests` |
| S03 | pass | `.swift-format` committed and enforced by the **Formatting** CI job (`swift-format lint --strict`, which ships with Xcode); the sources were formatted to it, so the check passes from a clean tree. The Swift build is the type check, and `Xcode project is up to date` is the static check on the generated project |
| S04 | pass | CI builds and tests on a matrix of `macos-15` (the pinned image a release is built on) and `macos-latest` (the newest image GitHub offers), `fail-fast: false`. macOS 14 is the deployment target but no runner image ships it; `README.md` → Requirements says so |
| S05 | pass | Secret scanning and push protection enabled (script) |
| S06 | pass | Settings live in the sandboxed `UserDefaults`; no committed credential, personal email or home-directory default; the Key Light address is user input |
| S07 | pass | Messages name the failed operation and its cause ("Bonjour browse failed: …", "Move OpenCamraHub to your Applications folder…"); no logging of tokens, headers or bodies, and light addresses are logged as `<private>` where they are not needed |
| S08 | pass | `.github/dependabot.yml` covers `github-actions`, the only ecosystem left; Dependabot alerts and security updates enabled; the maintainer triages them (`README.md` → Support and maintenance). Four Dependabot PRs were merged on 2026-09-20 |
| S09 | pass | Ruleset requires `Build and test` and `Xcode project is up to date` before merge (script) |
| S10 | pass | README "How it works" and `AGENTS.md` name the components and the constraints a contributor could break: broker identity, sandbox, frame tagging, hand-written scene coding, the rename invariants |
| S11 | pass | All 4 workflows declare `permissions` (script) |
| S12 | pass | All 10 `uses:` references satisfy the graduated table (script): SHAs in the write-capable stats job, major-version tags for GitHub's own actions in read-only jobs |
| S13 | na | No workflow uses `pull_request_target` or `workflow_run` (script) |

### Deployable

| ID | Result | Evidence |
|---|---|---|
| D01–D06 | na | The repository operates no deployment. Users install a release artifact (Package profile), and the GitHub Pages site is static hosting, which 1.15.0 states is not Deployable |

### Package

| ID | Result | Evidence / fix |
|---|---|---|
| R01 | pass | `Info.plist` carries `OCHDescription`, `OCHLicenseIdentifier`, `NSHumanReadableCopyright`, `OCHRepositoryURL` and `OCHIssueTrackerURL`; `README.md` → Metadata: what lives where names the authority for every property and what mirrors it, and `AppDisplayNameTests` fails when the bundle drifts from `LICENSE` |
| R02 | pass | `CHANGELOG.md` declares Semantic Versioning; the README states compatibility (macOS 14+) |
| R03 | pass | Both parts: the tag exists and names a commit, and the documented shared-pipeline procedure (`scripts/request.sh openlens vX.Y.Z --publish` in the broker, building the resolved commit) is in `README.md` → Releasing and `AGENTS.md` |
| R04 | pass | For 0.4.1 the tag `v0.4.1`, the `MARKETING_VERSION` the broker injects from it, and the release title `v0.4.1` agree |
| R05 | pass | No kit exists, and a dated record does: `docs/release-smoke-tests.md` names 0.4.1 (2026-09-19), the published assets, the checksum, provisioning-profile and `spctl` results, the install, launch, extension activation and the settings carried over, and names what it does not cover (frames into a consuming app). The 0.4.0 entry is there too. The build method has not changed since |
| R06 | pass | The 0.4.1 notes name specific changes and the upgrade concern (install this one by hand) |
| R07 | pass | The broker publishes the `CHANGELOG.md` entry as the notes and refuses when it is missing, empty or still under Unreleased; documented in `README.md` → Releasing and `AGENTS.md` |
| R08 | pass | `README.md` → Install states what `spctl` and the checksum prove, what they do not, and that each release carries the broker's `provenance.json` as the broker's own record rather than an independent attestation |

### Product Identity

| ID | Result | Evidence / fix |
|---|---|---|
| I01 | pass | Read from the published 0.4.1 bundle: `CFBundleName`/`CFBundleDisplayName` and `CFBundleShortVersionString` 0.4.1 |
| I02 | pass | Published bundle carries `OCHRepositoryURL` and `OCHIssueTrackerURL`; pinned by `AppDisplayNameTests` |
| I03 | pass | Published bundle carries `NSHumanReadableCopyright` and `OCHLicenseIdentifier` = MIT, agreeing with `LICENSE`; pinned by `AppDisplayNameTests` |
| I04 | pass | The About panel shows the version; **Help › OpenCamraHub on GitHub** and **Help › Report an Issue…** open the `Info.plist` URLs |
| I05 | pass | `AppIcon.icns` ships in the published bundle, and the same icon is on the site |
| I06 | pass | The broker injects `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` from the tag at build time |

### Documentation

| ID | Result | Evidence |
|---|---|---|
| T01–T05 | na | The Documentation profile does not apply: the product is software |

### Published Site

| ID | Result | Evidence / fix |
|---|---|---|
| W01 | pass | `.github/workflows/pages.yml` plus `scripts/build_site.sh` from the committed `site/`; rebuilt on site change, on release, and weekly |
| W02 | pass | The repository homepage is the site; the site header and footer link back |
| W03 | pass | The hero states what it is, for whom, and "Version 0.4.1, maintained" above the fold |
| W04 | pass | Name and sentence, status and the latest version, what it does, how to get it, privacy, links to repository, licence, security and support, and the review date |
| W05 | na | Retired in 1.12.0 |
| W06 | na | Retired in 1.12.0 |
| W07 | pass | System fonts only, no scripts, no third-party requests; stated in the page and the stylesheet header |
| W08 | pass | Contributor material stays in the repository; the site links to it |
| W09 | pass | Project-specific design (the crop-and-scene illustration, deck-key mock-ups), not a template |

### Agent Readiness

| ID | Result | Evidence / fix |
|---|---|---|
| G01 | pass | `AGENTS.md` at the root (script) |
| G02 | pass | `AGENTS.md` opens with purpose, a layout table and the authoritative build, test and project-generation commands, and the latest `ci.yml` run on `master` is green |
| G03 | pass | `AGENTS.md` → Forbidden and high-risk operations names force pushes, history rewriting, moving a published tag, credentials, releases and the user's scene data |
| G04 | pass | No tool-specific instruction file exists to diverge from `AGENTS.md`; `.github/github-app.yml` points at it rather than restating it |
| G05 | pass | `xcodebuild test …` succeeds from a clean checkout (193 tests; the Metal toolchain component is required and documented) |
| G06 | pass | `AGENTS.md` marks `OpenLens.xcodeproj` and `AppIcon.icns` as generated; the plugin `vendor/` is gitignored |
| G07 | pass | Agent commits carry `Co-Authored-By` and session trailers, and changes land through pull requests |
| G08 | pass | `.github/github-app.yml` points at `AGENTS.md` and names the validation commands |

### Language

| ID | Result | Evidence / fix |
|---|---|---|
| L01 | pass | `README.md` → Language: English is the interface language |
| L02 | pass | UI strings are English throughout |
| L03 | pass | `README.md` → Language: English only; the single `en.lproj` localizes the display name only |
| L04 | na | No localized build: `en.lproj/InfoPlist.strings` carries the display name, not translations |
| L05 | pass | Numbers use `.formatted`, and value fields accept both decimal separators (`NumberFieldValue.parse`) |
| L06 | na | No translated strings |
| L07 | pass | README, docs, code, commits, issues, PRs and release notes are English |

### Accessibility

| ID | Result | Evidence / fix |
|---|---|---|
| X01 | pass | Decided from source, as 1.15.0 allows. Read `OpenLensApp.swift`, `UI/ContentView.swift`, `UI/InspectorView.swift`, `UI/SceneStrip.swift`, `UI/LightingSection.swift`. No focus indicator is suppressed (no `focusEffectDisabled`, no `focusable(false)` on a control). Two gesture-only surfaces exist and both have keyboard equivalents: the preview's drag and scroll (zoom and pan) is matched by ⌘+, ⌘−, ⌘0, the Zoom field and Stepper, and the overlay's percentage fields and nine snap buttons; the scene tile's `onTapGesture` is matched by ⌃⌥1…⌃⌥9 and the Scene menu items. Everything else is a standard SwiftUI control, which is keyboard operable and shows focus by default |
| X02 | pass | Controls carry names and values: the tone, colour and zoom fields and sliders expose theirs, and the Key Light brightness and temperature sliders were given `accessibilityLabel`/`accessibilityValue` ("Studio links brightness", "25%"), verified in the accessibility tree of a running build |
| X03 | pass | System fonts and semantic colours throughout, no fixed pixel body text; meaning is never colour alone — the "adjusted" dot is accompanied by the text "N adjusted" and an accessibility label, and the `soft` zoom badge is text |
| X04 | pass | The only terminal output, the `openlens-mcp` CLI, is plain JSON and text with no colour or Unicode decoration |
| X05 | pass | `README.md` → Accessibility states the limitations, including the unnamed Key Light sliders found under `X02`, the pointer-only dragging with its keyboard equivalents, and that no systematic audit has been recorded |

### Data Protection and Privacy

| ID | Result | Evidence / fix |
|---|---|---|
| Y01 | pass | README and site privacy sections: collects nothing; the picture stays local except through the call |
| Y02 | pass | Both outbound connections named: the daily GitHub release check and Elgato Key Lights on the local network |
| Y03 | pass | No telemetry, analytics or crash reporting, stated |
| Y04 | pass | `README.md` → Privacy and your data: the preferences path, what it holds, how to export (copy the file) and delete (remove the container) |
| Y05 | pass | No third-party service or AI provider receives user content, stated |
| Y06 | pass | `README.md` → Privacy and your data: kept until deleted, survives uninstall and updates, and how to delete it |

### Archived

| ID | Result | Evidence |
|---|---|---|
| A01–A04 | na | The repository is not archived (script) |

## Where script and manual reading differ

None. Every criterion `scripts/assess.py` decided (19) matches the result
recorded here. The script left the remaining 85 `unknown`, as its draft says,
and this agent decided each one.

## Delta against the 1.13.0 assessment

Three results changed; everything else carries forward unchanged.

| ID | 1.13.0 | 1.15.0 | Why |
|---|---|---|---|
| `X01` | fail | pass | 1.15.0 widened the evidence: a review of the source by the assessing agent counts, and it does not need to run the product. The source shows no suppressed focus and a keyboard equivalent for every gesture-only surface |
| `R05` | partial | pass | 1.15.0 reworked `R05` around a smoke kit and dropped operating the core function as a requirement. The "no kit, but a dated record names the version installed and launched by hand and what was exercised" row is a `Pass`, and `docs/release-smoke-tests.md` is exactly that |
| `X02` | pass | pass | Reading the source found the Key Light brightness and temperature sliders carried no accessibility label, which the 1.13.0 `pass` had missed and the README disclosed as a limitation. Fixed in the same change as this assessment: both sliders now carry a label and a spoken value, verified in the accessibility tree of a running build |

`S04` stays `partial` under the widened rule, because both CI jobs pin
`macos-15` rather than the newest image available. `S03`, `B13` and `R01` are
unchanged.
