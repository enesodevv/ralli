# Ralli

**Your tennis lesson, taken to court.**

Ralli is an iOS app for recreational tennis players. Save the one tip your coach gave you, practise it in a short, focused session, and see what changes over the weeks.

It is built in SwiftUI with a 3D stroke viewer in SceneKit. There are no accounts and no servers: everything stays on the iPhone.

> **Status:** pre-release. The app runs end to end and is covered by unit and UI tests. It has not yet been piloted with players or reviewed by a tennis coach, so drill content and animations are still subject to change.

---

## Features

**Lesson notes**
- Write a note, or dictate it. Speech is recognised on the device where the iPhone supports it, and Ralli never stores audio.
- Turn a note into your active cue. It shows up on Today and travels with your next session.
- Unfinished notes are kept as drafts.

**Practice library**
- 17 drills: forehand, backhand, serve, return, volley, overhead, rally and footwork.
- Solo, with a partner, or against a wall.
- Each drill lists its goal, equipment, steps, a key cue, a common mistake, and an optional final check.
- Search, filters and favourites.
- A recommendation on Today that fits your focus, time, setup and level.

**Court mode**
- A dark, high-contrast session screen with a large timer that is readable in the sun.
- Pause and resume are the main action.
- At the end of each step: sound, haptic feedback, and a local notification if the app is in the background.
- Optional spoken cues.
- The screen stays awake during a session.
- A session can be saved and resumed later, even after the app is closed.

**3D stroke animations**
- Six motions: forehand, two-handed backhand, serve, volley, overhead and split step.
- Side, behind and front cameras; slow motion; phase labels such as Take-back, Contact and Follow-through.
- Every animation can be mirrored for left-handed players.
- With Reduce Motion on, nothing plays automatically and phases are stepped through by hand.
- In Low Power Mode, or when the phone gets hot, the scene drops to 30 fps without effects.

**Progress**
- The last 7 days at a glance, recorded practice time, and a full session history.
- Repeated final checks are compared only when the drill and test version match. Results are self-reported, and the app says so.

**Other**
- Six languages: English, Turkish, Spanish, German, French and Italian.
- Dynamic Type up to the largest accessibility sizes, VoiceOver labels and announcements, Reduce Motion support.
- An in-app privacy policy, a safety note on every drill, and a Settings screen.

## Privacy

- No account, no sign-in, no third-party analytics or advertising SDKs.
- Notes, sessions and preferences are stored locally with SwiftData.
- Analytics events (see `Analytics.swift`) are only written to the device log and never include note text.
- The privacy manifest (`PrivacyInfo.xcprivacy`) declares no tracking and no data collection.

## Requirements

- Xcode 26 or later
- iOS 17 or later (iPhone, portrait)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen), only if you change `project.yml`

There are no third-party packages.

## Getting started

```bash
git clone https://github.com/enesodevv/ralli.git
cd ralli/ralli
open Ralli.xcodeproj
```

Choose an iPhone simulator and run the **Ralli** scheme.

### Running on your own iPhone

Your Apple Developer Team ID is kept out of the repository. Create `ralli/Config/Signing.local.xcconfig` (it is gitignored) containing:

```
DEVELOPMENT_TEAM = ABCDE12345
```

Then change `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` to an identifier you own, and regenerate the project:

```bash
xcodegen generate
```

The project file is generated from `project.yml`. Make build-setting changes there, not in Xcode, or they will be lost on the next `xcodegen generate`.

## Tests

| Scheme | Platform | What it covers |
|---|---|---|
| `RalliPersistenceTests` | macOS | 18 tests: storage and data migration, recommendations, session recovery, localisation (every language matches English keys and format arguments), and a frame-by-frame **motion audit** |
| `RalliUITests` | iOS Simulator | 16 end-to-end flows driven like a player: onboarding, library, full sessions, save and resume across relaunch, journal, settings, swipe-back, largest text size, left-handed mode, and every tab in all six languages |

```bash
cd ralli
xcodebuild -project Ralli.xcodeproj -scheme RalliPersistenceTests -destination 'platform=macOS' test
xcodebuild -project Ralli.xcodeproj -scheme RalliUITests -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

UI tests use their own data store, so they never touch real data. The full UI run takes about 10 minutes.

### Motion audit

`MotionAuditTests` samples every animation, and its left-handed mirror, at 600 frames and fails if anything looks physically wrong:

- limbs change length, or knees bend backwards,
- the racket, arms or ball pass through the head or torso,
- planted feet slide,
- elbows flip, point into the chest, or bend past a natural range,
- the two-handed backhand loses its second hand,
- the ball is off the strings at contact.

## Project structure

```
ralli/
├── project.yml            XcodeGen spec (source of truth for the Xcode project)
├── Config/                Signing config (team ID goes in a local, ignored file)
├── Ralli/
│   ├── App/               App entry, tab navigation, debug launch options
│   ├── Core/
│   │   ├── DesignSystem/  Colours, type, shared components
│   │   ├── Models/        Drills, preferences, store, 3D motion model and IK
│   │   ├── Persistence/   SwiftData archive
│   │   └── Services/      Speech notes, spoken cues, render quality, analytics
│   ├── Features/          Today, Practice (library, session, 3D scene), Journal,
│   │                      Progress, Onboarding, Settings
│   └── Resources/         Assets, privacy manifest, six .lproj folders
├── Tests/                 Unit tests and motion audit (macOS)
├── UITests/               End-to-end UI tests (iOS)
└── docs/                  Design and content notes (Turkish)
outputs/                   Research, UX review, motion audit report and
                           App Store drafts (Turkish)
```

### Debug launch arguments

These are available in Debug builds only.

| Argument | Effect |
|---|---|
| `-ralli-show-intro` | Show the first-launch intro again |
| `-ralli-demo <drill-id>` | Open a drill's demonstration directly, e.g. `-ralli-demo serve` |
| `-ralli-contact-sheet <motion> <side\|behind\|front>` | 12 frames of one motion in a grid; append `-left` to the motion for the mirrored version |
| `-ralli-accessibility-qa` | Largest text size and Reduce Motion |
| `-ralli-ui-testing`, `-ralli-reset`, `-ralli-skip-intro` | Isolated store, wipe it, skip the intro (used by UI tests) |

## Content and disclaimer

Drills are written for Ralli and adapted from publicly available coaching guidance by the LTA and USTA. Ralli is independent and is not affiliated with, endorsed or sponsored by any federation.

The 3D animations are simplified illustrations of the order and rhythm of a stroke, not a technique analysis. Ralli does not replace a coach or medical advice.

## Documentation

- [Development log](ralli/README.md) (Turkish)
- [Design](ralli/docs/DESIGN.md), [redesign decisions](ralli/docs/REDESIGN.md) and [practice content](ralli/docs/PRACTICE.md) (Turkish)
- [Motion audit report](outputs/Ralli-Hareket-Denetimi.md) (Turkish)

## License

No license has been chosen yet, so all rights are reserved by default. Please open an issue before reusing the code or content.
