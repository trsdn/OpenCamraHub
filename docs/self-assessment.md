# Self-assessment: trsdn/OpenCamraHub

- Standard: trsdn Repository Quality Standard **1.13.0**
- Assessed on: 2026-09-19, at `master` after the 0.4.1 release
- State: **Needs work**
- Record: `.github/conformance.yml`
- Remediated: 2026-09-19, the same day; the per-criterion table below shows the results after remediation
- Method: `scripts/assess.py --repo trsdn/OpenCamraHub` decided 13 criteria from facts. Every other criterion was assessed by hand from the repository at `master` and read-only `gh api` calls, and decided by the rule text (decision 0011).

## Profiles

| Profile | Applies | Why |
|---|---|---|
| Public | Yes | Public repository |
| Software | Yes | Swift app, camera extension, Node tools |
| Deployable | No | The repository deploys to no environment it operates; users install a released artifact, which the Package profile covers |
| Package | Yes | Notarized DMG and ZIP release artifacts |
| Product Identity | Yes | An installed application |
| Documentation | No | The primary product is software, not documentation |
| Published Site | Yes | `trsdn.github.io/OpenCamraHub/` is published from `site/` |
| Archived | No | Active |

Automation is available (GitHub-hosted runners, `ci.yml`, `pages.yml`, `stats.yml`), so no result uses the Automation Availability substitutions.

## Result summary

104 criteria after remediation: **76 pass, 5 partial, 1 fail, 22 n/a**. The
first reading, before any fix, was 50 pass, 13 partial, 20 fail, 21 n/a.

The state stays *Needs work*, because the standard allows *Healthy* only with no
failing criterion. No critical gap from the Assessment rules was found at any
point: no committed secret, no exposed write-capable service, no unrecoverable
state, no unknown deployment.

What was fixed:

- **Settings:** private vulnerability reporting, secret scanning with push
  protection, Dependabot alerts and security updates, squash-only merges, the
  `trsdn-standard` topic, and the *Protect master* ruleset (no deletion, no
  force push, pull request plus both CI checks, no bypass).
- **Files:** `dependabot.yml`, `CODEOWNERS`, `github-app.yml`, the conformance
  workflow and this record; the README badge block, generated from sources;
  bundle metadata and Help menu links; the README sections on status, privacy
  and data, language, accessibility and support; credentials in `SECURITY.md`;
  purpose, layout and forbidden operations in `AGENTS.md`; a risk field in the
  PR template; the dated release smoke tests. The stats card and badges moved to
  the `repo-stats` branch, since the ruleset no longer lets a bot commit to
  master, and the `STATS_TOKEN` reference is gone.

## Remaining gaps, in priority order

1. `X01` fail: no recorded keyboard-operability check of focus order and the
   focus indicator. Fix: run one end to end and record it, or add a UI test.
2. `R05` partial: frame delivery through the virtual camera into a consuming app
   is not yet recorded for 0.4.1. Fix: check in Teams, Zoom or Photo Booth and
   add it to `docs/release-smoke-tests.md`.
3. `S04` partial: CI runs macOS 15 only, while macOS 14 is supported. Fix: a
   `macos-14` job, which needs the Metal toolchain on that image.
4. `S03` partial: no formatter or linter in CI. Fix: swift-format or SwiftLint.
5. `B13` partial: release procedure described in both README and `AGENTS.md`,
   and deep-dive material in the README. Fix: one home, linked from the other.
6. `R01` partial: see the table.

## Per-criterion evidence

### Baseline

| ID | Result | Evidence / fix |
|---|---|---|
| B01 | pass | Name "OpenCamraHub" plus a description stating the purpose (GitHub metadata) |
| B02 | pass | `README.md` states purpose, audience, a **Status** line, install and usage, and key links |
| B03 | pass | `LICENSE`, MIT, detected by GitHub |
| B04 | pass | `.gitignore` ignores `.build/`, `xcuserdata/` and the generated plugin `vendor/`. The generated `.xcodeproj` is committed deliberately and says why |
| B05 | pass | README "Build from source" and the PR template document the `xcodebuild test …` command; it ran successfully locally (191 tests) and in CI |
| B06 | pass | Squash is the only allowed merge method (repository settings and the ruleset's `allowed_merge_methods`); branches are deleted on merge; Dependabot and secret-scanning alerts are enabled, so open alerts are visible |
| B07 | pass | README Requirements: macOS 14, arm64, Xcode 16. Plugin needs Node 20 (`install.sh`). `project.yml` has the deployment target |
| B08 | pass | `CHANGELOG.md` (Keep a Changelog), GitHub releases, linked issues |
| B09 | pass | Public, 12 topics, homepage set to the site, not archived |
| B10 | pass | `.github/CODEOWNERS` (`* @trsdn`) and `README.md` → Support and maintenance |
| B11 | pass | `.github/conformance.yml` committed, validated by `.github/workflows/conformance.yml` |
| B12 | pass | `trsdn-standard` topic set on the repository |
| B13 | partial | The release procedure is restated in both README "Releasing" and AGENTS.md, and the README carries deep-dive material (Performance, capture quality) that belongs in `docs/`. Fix: pick one home and link to it |
| B14 | na | The repository holds and references no credential: workflows use only `GITHUB_TOKEN` (the former `STATS_TOKEN` reference is gone). `SECURITY.md` → Credentials names the Apple credentials in the broker and who replaces them |
| B15 | na | Nothing third-party is redistributed. Since #42 the app has no package dependencies, and the plugin's `vendor/` is a copy of this repository's own `openlens-mcp` client |
| B16 | pass | Ruleset *Protect master* (active, no bypass actors): blocks deletion and non-fast-forward pushes on the default branch |

### Public

| ID | Result | Evidence / fix |
|---|---|---|
| P01 | pass | MIT, OSI-approved (script) |
| P02 | pass | `CONTRIBUTING.md` and `CODE_OF_CONDUCT.md` recognized (script) |
| P03 | pass | Private vulnerability reporting enabled (`GET repos/trsdn/OpenCamraHub/private-vulnerability-reporting` → `enabled: true`); `SECURITY.md` and the issue chooser link to it |
| P04 | pass | Issue forms and a PR template exist (script) |
| P05 | pass | `README.md` covers install, configuration, examples, compatibility (Requirements), security (links `SECURITY.md`) and support status |
| P06 | pass | Community profile complete (script) |
| P07 | pass | Description, 12 topics, homepage |
| P08 | pass | Badge block in the required order: license, platform, CI, latest release, conformance. License, platform and release are rendered by `scripts/badges.py` from `Info.plist`, `project.yml` and git tags into the `repo-stats` branch; CI is GitHub's own workflow badge; conformance is generated from the record. The hard-coded Swift and Apple Silicon badges are removed |
| P09 | pass | `stats.yml` regenerates `.github/stats/repo-card{,-dark}.svg` on a schedule, and the README selects them with `<picture>` |
| P10 | pass | Bug form asks what happened, expected vs actual ("What you expected, and what happened instead"), steps, app version, macOS and Mac model, camera and consumer app. Blank issues disabled |
| P11 | pass | `.github/PULL_REQUEST_TEMPLATE.md` asks what and why, the linked issue, **Risk**, and validation |

### Software

| ID | Result | Evidence / fix |
|---|---|---|
| S01 | pass | Generated project committed; no package dependencies; documented `xcodebuild` command |
| S02 | pass | 191 XCTest cases (renderer, scene persistence, pause gating, release check and more), run in `ci.yml`. The plugin has its own `npm test` (37 checks), which CI does not run |
| S03 | partial | CI type-checks via the Swift build and checks the generated project is current, but runs no formatter or linter (SwiftLint or swift-format; none for the plugin JS). Fix: add one |
| S04 | partial | Supported: macOS 14+ on arm64. CI runs only `macos-15`, so macOS 14 is untested. Fix: add a `macos-14` job, or state that macOS 14 is supported untested |
| S05 | pass | Secret scanning and push protection enabled (`security_and_analysis`) |
| S06 | pass | Settings live in the sandboxed `UserDefaults`, with no credentials; the Key Light address is user input; no default sends data anywhere |
| S07 | pass | Errors surface as actionable banners ("Move OpenCamraHub to your Applications folder…"); `os.Logger` is used, with no credentials to leak |
| S08 | pass | `.github/dependabot.yml` covers `github-actions` (the only remaining dependency ecosystem); Dependabot alerts and security updates enabled; the maintainer triages them (`README.md` → Support and maintenance) |
| S09 | pass | Ruleset *Protect master* requires the `Build and test` and `Xcode project is up to date` checks and a pull request |
| S10 | pass | README "How it works" and AGENTS.md record the non-obvious constraints: broker, sandbox, frame tagging, scene format, rename identity |
| S11 | pass | All 3 workflows declare `permissions` (script) |
| S12 | pass | All 7 `uses:` references satisfy the table (script) |
| S13 | na | No `pull_request_target` or `workflow_run` (script) |

### Deployable

| ID | Result | Evidence |
|---|---|---|
| D01–D06 | na | The repository operates no deployment; users install the release artifact (Package profile) |

### Package

| ID | Result | Evidence / fix |
|---|---|---|
| R01 | partial | `Info.plist` carries name, version, bundle id and icon, but no licence or repository properties, and the README does not say where each property lives. Fix: item 8 |
| R02 | pass | `CHANGELOG.md` declares Semantic Versioning; README states compatibility (macOS 14+) |
| R03 | pass | Shared pipeline: README "Releasing" and AGENTS.md document `scripts/request.sh openlens vX.Y.Z --publish` in the broker, which builds the tag's pinned commit and uploads the assets |
| R04 | pass | The broker resolves the tag, confirms it has not moved, and injects `MARKETING_VERSION` from it; release titles equal the tag (`v0.4.1`, `v0.4.0`, `v0.3.1`) |
| R05 | partial | `docs/release-smoke-tests.md` records 0.4.1 and 0.4.0: published artifact downloaded, verified, installed, launched, extension activated, settings carried over. Frame delivery through the virtual camera into a consuming app is recorded as not yet exercised for 0.4.1 |
| R06 | pass | 0.3.1, 0.4.0 and 0.4.1 notes are the changelog entries, including upgrade concerns (the 0.4.1 manual-install note) |
| R07 | pass | The broker creates the release with the `CHANGELOG.md` entry as notes and refuses when the entry is missing, empty or still under Unreleased (it refused 0.3.1 until the changelog existed); documented in `README.md` → Releasing and `AGENTS.md` |
| R08 | pass | `README.md` → Install states what the `spctl` and checksum check proves and what it does not; each release carries the broker's `provenance.json` |

### Product Identity

| ID | Result | Evidence / fix |
|---|---|---|
| I01 | pass | `CFBundleName`/`CFBundleDisplayName` plus `CFBundleShortVersionString` in the built bundle |
| I02 | pass | `Sources/OpenLens/Info.plist`: `OCHRepositoryURL`, `OCHIssueTrackerURL`; pinned by `AppDisplayNameTests` |
| I03 | pass | `Sources/OpenLens/Info.plist`: `NSHumanReadableCopyright`, `OCHLicenseIdentifier` = MIT, agreeing with `LICENSE`; pinned by `AppDisplayNameTests` |
| I04 | pass | The About panel shows the version; **Help › OpenCamraHub on GitHub** and **Help › Report an Issue…** open the URLs from `Info.plist` |
| I05 | pass | `AppIcon.icns` is in the bundle, and the same icon is on the site (`site/assets/icon.png`) |
| I06 | pass | The broker injects `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` from the tag at build time |

### Documentation

| ID | Result | Evidence |
|---|---|---|
| T01–T05 | na | Documentation profile does not apply |

### Published Site

| ID | Result | Evidence / fix |
|---|---|---|
| W01 | pass | `.github/workflows/pages.yml` plus `scripts/build_site.sh` (committed `site/`); rebuilt on site change, on release, and weekly |
| W02 | pass | Repository homepage is the site; the site header and footer link to the repository |
| W03 | pass | The hero states what it is, for whom, and "Version 0.4.1, maintained" before scrolling |
| W04 | pass | Name and sentence, status and version, what it does (illustration), how to get it, privacy disclosure, links to repo, licence, security and support, and the review date |
| W05 | na | Retired in 1.12.0 |
| W06 | na | Retired in 1.12.0 |
| W07 | pass | System fonts only, no scripts, no external requests; stated in the page's privacy section and the stylesheet header |
| W08 | pass | Contributor material stays in the repository; the site links to it |
| W09 | pass | Project-specific design (crop-and-scene illustration, key mock-ups), not a template |

### Agent Readiness

| ID | Result | Evidence / fix |
|---|---|---|
| G01 | pass | `AGENTS.md` at the root (script) |
| G02 | pass | `AGENTS.md` opens with purpose, a layout table and the authoritative build, test and project-generation commands |
| G03 | pass | `AGENTS.md` → Forbidden and high-risk operations: force pushes, history rewriting, tag moves, credentials, releases, and the user's scene data |
| G04 | pass | No tool-specific instruction files to diverge |
| G05 | pass | `xcodebuild test …` succeeds from a clean checkout (191 tests; needs the Metal toolchain component) |
| G06 | pass | AGENTS.md marks `OpenLens.xcodeproj` as generated and `AppIcon.icns` as generated; the plugin `vendor/` is gitignored |
| G07 | pass | Agent commits carry `Co-Authored-By` and session trailers; changes land through PRs |
| G08 | pass | `.github/github-app.yml` points at `AGENTS.md` and names the validation commands |

### Language

| ID | Result | Evidence / fix |
|---|---|---|
| L01 | pass | `README.md` → Language: English is the interface language |
| L02 | pass | UI strings are English throughout |
| L03 | pass | `README.md` → Language: English only; the single `en.lproj` localizes only the display name |
| L04 | na | No localized build: the single `en.lproj/InfoPlist.strings` carries the display name, not translations |
| L05 | pass | Numbers use `.formatted`, and value fields accept both decimal separators (`NumberFieldValue.parse`) |
| L06 | na | No translated strings |
| L07 | pass | README, docs, code, commits, issues, PRs and release notes are in English |

### Accessibility

| ID | Result | Evidence / fix |
|---|---|---|
| X01 | fail | No documented keyboard-operability check or test. Fix: record one |
| X02 | pass | `accessibilityLabel` on value fields, sliders and state indicators in `InspectorView.swift` |
| X03 | pass | System fonts and semantic colours; the "adjusted" dot also has text ("1 adjusted") and an accessibility label |
| X04 | pass | The only terminal output (the `openlens-mcp` CLI) is plain JSON and text, with no colour |
| X05 | pass | `README.md` → Accessibility lists known limitations (pointer-only dragging with keyboard equivalents, unnamed Key Light sliders, no recorded audit) |

### Data Protection and Privacy

| ID | Result | Evidence / fix |
|---|---|---|
| Y01 | pass | Site privacy note: collects nothing, the picture stays local except through the call |
| Y02 | pass | Same note: daily GitHub release check; Elgato Key Lights on the local network (Bonjour and HTTP) |
| Y03 | pass | No telemetry, analytics or crash reporting, stated |
| Y04 | pass | `README.md` → Privacy and your data: the preferences file path, what it holds, how to export (copy) and delete (remove the container) |
| Y05 | pass | No third-party service or AI provider receives user content, stated |
| Y06 | pass | `README.md` → Privacy and your data: kept until deleted, survives uninstall and updates, and how to delete it |

### Archived

| ID | Result | Evidence |
|---|---|---|
| A01–A04 | na | Not archived |

## Where script and manual reading differ

None contradicted. The script left `B16` and `S09` unknown: the 404 from the protection endpoint is ambiguous in general. Read with an admin token, the endpoint says "Branch not protected" and the rulesets list is empty, which settles both as `fail`.
