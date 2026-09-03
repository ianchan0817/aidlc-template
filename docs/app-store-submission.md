# App Store submission

Applies when `project.yml` declares a `mobile` surface with an iOS target.
Reference for shipping an iOS build to App Store Connect, and the canonical body
behind `/app-store-submit`. Read it **before** the first archive, not after the
first rejection.

The engineering is rarely what costs the time. Apple reports most causes as an
unrelated symptom, in a dialog with no detail, hours after the edit that caused
it. Three habits remove most of that cost:

1. **Settle identity before building.** Bundle id, team, build number.
2. **Assert against the built artifact, never the config that fed it.**
3. **Read the real logs.** Every distribution failure writes a verbose log that
   names the actual query and its result. The dialog never does.

## Symptom → cause

The left column is what you see. The right column is never visible from it.

| Symptom | Actual cause |
|---|---|
| `IDEDistribution.DistributionAppRecordProviderError error 0` | No App Store Connect **app record** matches the archive's bundle id. A bundle id registered in the Developer Portal is *not* an app record. |
| `Unable to Add for Review — You must choose a build` | No uploaded build has finished processing for that version. Not a metadata error; nothing on the page can clear it. |
| App Store Connect demands iPad screenshots you don't want | The uploaded build's `UIDeviceFamily` includes `2`. Decided by the build, not by the version page. |
| `The archive did not include a dSYM for <Vendor>.framework` | A **static** vendor framework is in an *embed* phase. Embedding produces a dylib at build time whose UUID changes per build, so the requested dSYM cannot exist. Link it instead; then nothing is embedded and nothing is asked for. |
| App Store Connect lists a minimum OS you did not choose | The uploaded build's `MinimumOSVersion`. The exporter's deployment target, not the Xcode project you edited by hand. |
| Upload rejected: encryption / export compliance outstanding | `ITSAppUsesNonExemptEncryption` missing from `Info.plist`. |
| Upload rejected: duplicate build | Build number already used for that version string. |
| Distribute succeeds but the build never appears | Processing takes 5–30 min, longer on a first submission. Wait before debugging. |
| Rejected **Guideline 2.1 — Information Needed** on a first submission | The App Review Information → Notes field was empty. Not a defect finding: the reviewer is asking for context. Reply in the thread; no new build required. |
| AdMob says "we couldn't verify" your app after the store listing is linked | `app-ads.txt`. Almost never the file's contents — usually there is no developer website URL on the store listing for Google to read a domain from, or that domain cannot serve a file at its root. |
| Screenshot upload silently refuses a file | Wrong pixel dimensions (zero tolerance), or an alpha channel. Convert to RGB. |
| `Undefined symbol` linking only in Debug, never Release | A static archive member is pulled in one configuration and dead-stripped in the other. The missing symbol is genuinely absent from the library in both. |

## Gate 1 — identity, before the first build

**Bundle id: read it off the app record.** App Store Connect → your app → App
Information → Bundle ID. That field is the only authority.

Do **not** infer it from any of these. Each can be present, plausible, and wrong:

- the export preset or project config in your repo — may predate a rename
- a previous archive — may have been built against a since-changed value
- an installed provisioning profile — proves a *bundle id* exists, not an app

When Xcode distributes, it queries the record by bundle id. The verbose log
shows the query and the count:

```
filter[bundleId]=<what your archive declares>
AppsService: fetched 0 items, total 0 items
```

`0 items` surfaces in the UI only as `DistributionAppRecordProviderError`.

**Do not rename the bundle id to match a product rename.** It is an identity
Apple issued the record against, not a name. Renaming it orphans the listing and
every ad-network app entry keyed to it. Mark it exempt in the repo's own docs,
because the failure appears at distribution time, long after the edit.

**Team id.** Verify against a current provisioning profile, not the config. A
stale team id in a generated project matches no distribution profile.

**Build number.** Unique per version string, monotonic. Bump before archiving.

## Gate 2 — settings that only fail after upload

Cheap to set now, expensive to discover later: each costs a fresh archive, a
fresh upload, and another processing wait.

- **Device family.** Decide iPhone-only vs universal *before* uploading. It
  determines which screenshot slots App Store Connect demands. Shipping
  universal also means the reviewer exercises your layout on an iPad, so a UI
  never tuned for one invites layout rejections on top of the screenshot rule.
- **Deployment target: iOS 15.6 minimum.** Set `IPHONEOS_DEPLOYMENT_TARGET` in the
  exporter, not the generated project, or the next export reverts it. Apple sets no
  minimum deployment target — this is a project constraint, and lowering it below
  15.6 needs a decision, not a default. What Apple *does* mandate is the **build
  SDK**: uploads must be built with Xcode 26 or later using the iOS 26 SDK. The two
  are independent — a current SDK does not raise your floor, and a low floor does
  not exempt you from the SDK requirement.
- **Export compliance.** `ITSAppUsesNonExemptEncryption`. If the app only uses
  OS-provided HTTPS, the honest declaration is `false`.
- **Third-party static frameworks: link, do not embed.** Check before deciding —
  `file <Framework>/<Binary>` reporting `current ar archive` means static.
- **Tracking permission.** Do not declare a tracking usage description unless
  you actually request tracking. For a child-directed app you must not.

## Gate 3 — verify the artifact, never the config

The config is what you intended. The built `Info.plist` is what Apple grades.

| Assert | Why it bites |
|---|---|
| `CFBundleIdentifier` | The one value that must match the app record |
| `CFBundleVersion` | Duplicate build numbers are rejected at upload |
| Encryption key present | Blocks the version page until supplied |
| Ad-network app id is the **production** id | A post-export script defaulting to debug ships test ids |
| `MinimumOSVersion` | Must be **15.6 or higher**; a correct build setting still exports wrong |
| `UIDeviceFamily` | Decides your screenshot obligations |
| Exactly one data pack, named after the executable | Engines that load `<executable>.pck` fail at launch, not at build |
| No unexpected `Frameworks/` directory | An embedded static framework is the dSYM warning |

Read values without mutating the file:

```bash
plutil -extract <Key> raw -o - <path>/Info.plist
```

**`plutil -extract <Key> <fmt> <file>` without `-o -` overwrites the file with
the extracted value** for non-`raw` formats. It will silently destroy a plist.

An incremental build keeps the previous run's stale resources beside the new
ones, so name-related assertions only mean something against a clean output
directory.

## Gate 4 — signing

An archive signed with a **development** certificate cannot be distributed to
the App Store, even though it archives cleanly. Check before assuming an upload
worked:

```bash
security find-identity -v -p codesigning       # need an "Apple Distribution" entry
codesign -dv --verbose=2 <App>                 # Authority line names the cert used
```

A profile whose entitlements carry `get-task-allow = true` is a development
profile. App Store profiles have it `false` and list no devices.

Creating the distribution certificate, and uploading, both require
authenticating to the Apple account — a person has to do that. Plan for it
rather than discovering it at the end.

Distribution logs live in a temp directory and contain a **live Apple session
token** plus the account address. Never attach them to an issue or paste them
into a chat you don't control.

## Gate 5 — metadata that blocks "Add for Review"

- **Support URL** — required, and publicly reachable. A private repository's URL
  404s for the reviewer, which is a rejection.
- **Privacy policy URL** — required, and enforced strictly for kids apps.
- **Screenshots** — exact dimensions, RGB, no alpha. Apple documents scaling only
  *downward within* a device family, so an iPhone image cannot fill an iPad slot.
- **Age rating, category, pricing** — cheap, and each blocks submission alone.

## Gate 6 — App Review Information

Apple issues **Guideline 2.1 — Information Needed** against practically every
first submission whose Notes field is empty. It is not a defect report and needs
no new build; it is answered in the review thread. Filling the field before the
first submission removes an entire review round trip, measured in days.

Answer all seven, even where the answer is "none" — an omitted item reads as
unanswered:

1. A screen recording from a **physical device** on the current OS, starting at
   launch and walking the core flow. Include registration/login/deletion, any
   purchase flow, user-generated content with its reporting and blocking
   controls, and any permission prompt — or state explicitly that the app has
   none of them.
2. Device models and OS versions tested. Must be true of the **submitted
   build**, not an earlier one.
3. What the app does, who it is for, the problem it solves.
4. How to set up and reach the main features; demo credentials if any.
5. Every external service behind core functionality — data providers, auth,
   payments, AI, ad networks.
6. Regional differences, or an explicit statement that behaviour is identical
   everywhere.
7. Regulated-industry or third-party-material authorisation, or that neither
   applies.

Keep the answer in the Notes field permanently; it is re-read on every release,
and a stale device list there is worse than none.

## Generated Xcode projects

Applies to Godot, Unity, Unreal, Capacitor, Tauri — anything that emits the
Xcode project rather than owning it.

**The generated project is output. Never fix anything there and expect it to
last** — the next export overwrites it. Fix the exporter's config, or add a
post-export script that reapplies the change idempotently and fails loudly.

**An option absent from the config file is at its default, not absent from the
tool.** Exporters commonly serialise only non-default values, so searching the
config and finding nothing proves nothing — check the exporter's own option
list. Concluding "the tool can't do this" from a missing key leads to
hand-patching generated output forever.

**Config a generator does not regenerate can hide in an ignored directory.** If a
plugin descriptor or entitlement file is hand-maintained but sits under an
ignored path, the fix exists on one machine and dies with it. Track the text file
and keep ignoring the binaries beside it. Git cannot re-include a file under an
excluded directory, so this needs an un-ignored parent:

```gitignore
plugins/*
!plugins/<name>/
plugins/<name>/*
!plugins/<name>/*.<ext>
```

Verify with `git check-ignore <path>`, which exits **1** once a negation has
re-included the file and **0** while it is still ignored, naming the rule under
`-v`. Prefer it to `git add -An`, which exits 0 either way and reports the
difference only as text a script will miss.

**Editor and export templates must be the same version.** A mismatch fails as a
crash or a link error, never as a clear version message. Engine plugins built
against engine internals need rebuilding on every version change.

**Name the project from the config, and let scripts discover the name.** A
post-export script that hardcodes the product name breaks on the first rename,
usually by silently patching a file that no longer exists. Discover the single
`*.xcodeproj` in the export directory and derive paths from it; treat two as an
error.

**Renaming a generated Xcode project by hand needs three things, not one:** the
`.pbxproj` values (where any value containing a space must gain quotes, and
`key = value;` pairs sitting mid-line after an object id are easy to miss),
`project.xcworkspace/contents.xcworkspacedata`, which carries its own
`self:<name>.xcodeproj` reference, and the scheme filename. A stale workspace
reference makes the editor recreate the old project directory beside the new one.
Xcode reports any of these as "the project is damaged", with no line number.

## Kids category with ads

Stricter than the general App Store, and the rules interact:

- Tag every ad request child-directed **and** non-personalised. Different flags;
  set both.
- Never request tracking permission.
- Guideline **2.5.18** expects an in-app way to report an inappropriate ad.
- Google Play's Families policy is stricter than Apple's on ads to under-13s.
  Settle that before porting, not after.
- Interstitial frequency is a product decision with a review dimension: a
  full-screen ad a four-year-old cannot dismiss is both a retention cost and a
  rejection risk.

## app-ads.txt, for ad-supported apps

Not an App Store gate. It blocks nothing in review, and getting it wrong costs
ad revenue rather than a rejection — unverified inventory is worth less because
some buyers only bid on authorized inventory. Do it before launch, but do not
let it hold up a submission.

The chain has three links and the failure message names none of them:

1. The **store listing** must carry a developer website URL. That is the only
   place the ad network learns which domain to crawl.
2. That domain must serve the file **at its root**, as `text/plain`, with no
   BOM: the path is `/app-ads.txt` and nothing may sit in front of it.
3. The file must contain the network's publisher line verbatim.

Failures cluster on links 1 and 2 while the message points at 3. A listing with
no developer URL, a URL whose host you cannot place a root file on, or a file
behind a redirect that leaves the registrable domain all produce the same
"details don't match".

A private repository cannot serve it, and GitHub Pages needs a public repo. If
the app has no website yet, this is the forcing function that creates one — and
the same site can carry the Support and Privacy Policy URLs the store listing
requires anyway, so build all three at once.

Check it the way the crawler does, not by opening it in a browser:

```bash
SITE=...   # the developer URL from the store listing, scheme included
curl -sSIL "$SITE/app-ads.txt" | grep -iE '^HTTP/|^content-type'
curl -sSL  "$SITE/app-ads.txt"
```

Expect a final `200`, `content-type: text/plain`, and the publisher line. A
`301` chain that ends on a different registrable domain fails even though a
browser follows it happily.

## Order of operations

Each step invalidates everything after it, so going out of order means redoing
work:

1. Read bundle id, team, and the required metadata list off App Store Connect
2. Set device family, encryption, and framework link/embed in the **exporter**
3. Build; assert Gate 3 against the artifact
4. Confirm a distribution certificate exists
5. Archive, upload, wait for processing
6. Fill metadata; select the processed build
7. Submit
