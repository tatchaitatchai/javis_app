# MVP 1 Calm Ambient redesign (UI only)

Status: Implemented (UI with mock data); backends not started
Last updated: 2026-11-01

## Context

The approved MVP 1 flow design lives in `../thesis/redesign/flow/` (24 Calm
Ambient screens, PNG exports in `../thesis/redesign/png/`). MVP 1 covers phone
OTP sign-in, multiple homes, zones, members, scenes, five Tuya bulbs and one
Conlock CL-X1 (Tuya) door lock. The Go API does not provide these features yet.

The owner asked to redesign the whole app to that flow, UI first, with the
original Calm Ambient theme (cream `#F2F0E8`, ink `#253026`, sage `#667860`,
gold) and mock data. Taps must feel immediate and smooth, and the code must stay
organized.

## Goal

- Rebuild every screen of the 24-screen flow in Flutter and link them into one
  navigable app.
- Use in-memory mock data for account/OTP, homes, zones, members, invites,
  scenes and the lock.
- Keep the existing `LightingService` (demo and Tuya providers) as the only
  source of bulb state and commands, including pairing.
- Give every tappable control instant visual feedback (press scale/colour),
  light haptics, and short animations that respect Reduce Motion.

## Non-goals

- Go API, real SMS OTP, persistence across launches, real invitations.
- Real door-lock integration, Face ID, or any lock command to hardware.
- Real voice recognition or microphone access (screen 21 is a labelled
  preview).
- New packages, state-management or routing libraries.
- Changing the Tuya bridge, pairing state machine or command semantics.

## User flow

Signed out:

1. Welcome (01) → Phone (02, +66) → OTP (03, six boxes, resend countdown).
2. The demo number `081 234 5678` is an existing account and opens the
   dashboard with the seeded home. Any other valid Thai mobile number is a new
   account: Profile name (04, step 1/3) → Create home (05, step 2/3, presets,
   pending-invite card) → Zones (06, step 3/3 multi-select) → Dashboard.
3. The invite card opens Invite accept (08); joining adds the shared home and
   opens it.

Signed in (bottom tabs: Home / Scenes / Me):

- Dashboard (09): home switcher title, voice and add buttons, lock card, scene
  pills, zone filter chips, two-column device grid with inline power toggles,
  offline tile.
- Home switcher sheet (07): homes with role/zone/device summary, add home,
  settings of the current home.
- Zone (10): lights in one zone, turn all off, scenes using that zone, add
  device into the zone.
- Bulb (11): vertical brightness slider, power button, white/colour segment,
  temperature slider, colour swatches, quick presets, remove (real devices).
- Lock (12) and Unlock confirm sheet (13): slide to confirm. Status changes to
  “Unlocked” only when the (mock) lock reports it, then auto-locks.
- Add device: type picker (14) → bulb setup on the existing pairing flow
  restyled after 15–17 → success with name and zone (18). The lock type shows
  “coming soon” because no lock pairing exists.
- Scenes (19) and Scene editor (20); Voice preview (21).
- Home settings (22), Members invite (23), Me (24) with language switch and
  sign out.

## Data and boundaries

- `AppScope` (InheritedWidget) exposes `LightingService`, `AccountStore`,
  `HomeStore`, `LockStore` and `SceneStore` to the widget tree.
- All four new stores are in-memory `ChangeNotifier`s with seeded demo data and
  no I/O. They are the seam the Go API will replace later.
- Lights come only from `LightingService`. They are shown in the primary
  (provider-connected) home; other homes show an empty device state. Zone
  membership is `HomeStore` override → `LightDevice.room`. A name typed on the
  success screen is stored as a local display name, never sent to Tuya.
- Seeded zone and demo device names are translated (they are app-authored).
  Names typed by the user are never translated.

## Acceptance criteria

- Every one of the 24 screens is reachable from the running app, styled after
  the design tokens and layout.
- Demo and Tuya bulb behaviour is unchanged: capability-gated controls,
  pending/duplicate protection, offline and error states, no demo fallback in
  Tuya mode, removal only for real devices, pairing generations and key test
  keys (`pairing-ssid`, `pairing-password`, `choose-home-wifi`, …).
- Mock-only data (lock, other homes, members, OTP, voice) is labelled as a
  preview where a user could mistake it for real control.
- Taps show feedback within the same frame; toggles flip optimistically while
  the command is pending and revert on failure; animations shorten to
  near-instant with Reduce Motion.
- Thai and English for every new string; Dynamic Type at 2× does not overflow;
  48 pt minimum touch targets; VoiceOver labels on icon buttons; light and dark
  themes.

## Implementation notes

- Tokens live in `core/theme/` as a `CalmPalette` theme extension (light and
  dark). Shared press/motion helpers live in `core/motion/`; reusable controls
  in `core/widgets/`.
- Pairing logic in `add_device_screen.dart` is kept; only its presentation
  changes. The device-type picker and success form wrap it.
- Localized strings for each feature live in a `part` file next to the catalog
  so the single typed catalog stays scannable (`home_strings`, `device_strings`,
  `scene_strings`, `account_strings`).
- Top bars are pinned above the scroll view (`FlowPage`, pairing) so Back and
  Save stay reachable at large text. Footers sit in `SliverFillRemaining`.
- Widgets that read a store listen to it themselves (`ListenableBuilder`); a
  `const` child is not rebuilt by its parent. Route builders capture stores
  before `push` so a locale change cannot touch a deactivated context.
- `TileGrid` lays rows out with `IntrinsicHeight`, so tiles in a row share one
  height.
- The dashboard door card and the locked lock hero stay ink in both themes
  (`CalmPalette.light.strong`); the inverted cream surface glared on the dark
  canvas and lowered the gold icon's contrast.
- Moved to shared files: `CalmSegment` (`core/widgets/calm_segment.dart`),
  `ThaiPhoneField`/`ThaiMobileFormatter` (`features/account/phone_field.dart`).
  `pairing_widgets` `StepState` is now `ChecklistState` (it clashed with
  Material).
- Old screens replaced by the redesign (`home_shell.dart`, `rooms_screen.dart`,
  `lighting_widgets.dart`) were moved out of the project into the session
  scratchpad, not deleted. `ambient_widgets.dart` keeps only `AdaptivePage`,
  `CalmColumns` and `DemoNote`.
- Preview-only items, labelled in the UI: door notifications switch, voice
  screen, Face ID line on the unlock sheet, lock pairing (“coming soon”), the
  theme row (follows the system; display only). Test-blink and remember-Wi-Fi
  from the design are not built.
- The demo success copy now says “sample bulb” so it does not imply hardware.
- `FlowTopBar` side slots hug their content (56–132 pt) instead of a fixed 56 pt.
  The fixed width left 36 pt for a `QuietButton` label, which broke the Thai
  “ยกเลิก” and “บันทึก” mid-word in the scene editor. A title stays centered in the
  remaining space, so it can sit a few points off-center when the two side
  actions differ in width.
- `javis_app/AGENTS.md` still mentions `RoomArtwork`, which no longer exists;
  left unchanged pending the owner's decision. The old `scene()` string in the
  catalog is unused.

## Risks and unverified items

- CL-X1 remote unlock support, lock pairing mode and real battery/door reporting
  are unverified; the lock UI is mock only.
- The “switch off and on three times” bulb reset step comes from the design and
  is unverified for the purchased bulb; the real flow keeps the existing
  network-path guidance.
- SMS OTP delivery to +66 numbers and invitation by phone need the Go API and an
  SMS provider; not verified.

## Verification

2026-11-01:

- `dart format --output=none --set-exit-if-changed .` — 0 changed.
- `flutter analyze` — no issues.
- `flutter test` — 49 passed. `widget_test.dart` covers OTP sign-in, new
  account onboarding, light toggle/detail, demo pairing, lock unlock and
  auto-lock, scenes, members and sign out, dark theme with 2× text, iPad
  portrait width, Thai/English switch, and a locale change during discovery.
  `lighting_service_test.dart` keeps the existing provider, pairing-generation
  and removal regressions.
- iOS 17 simulator (iPhone 15 Pro, demo provider), checked by eye: welcome,
  phone formatting, OTP → dashboard; device type → demo pairing → success →
  done; dashboard grid; Scenes; Me; unlock sheet slide → “Unlocked” → auto-lock
  after 10 s with the activity log updated; lock screen; dashboard and lock
  screen in dark mode.
- Not checked by eye on the simulator (widget tests only): home settings,
  members invite, voice preview, scene editor, Thai on device. Not run on a
  physical iPhone or with the Tuya provider.

2026-11-05:

- After the `FlowTopBar` change: `dart format` 0 changed, `flutter analyze` no
  issues, `flutter test` 55 passed. `flow_top_bar_test.dart` fails when the side
  slots are limited to 56 pt again.
- iOS 17 simulator (iPhone 15 Pro, demo provider, Thai), checked by eye: the
  scene editor shows “ยกเลิก” and “บันทึก” on one line. Other `FlowTopBar` screens
  were not rechecked by eye after this change.
