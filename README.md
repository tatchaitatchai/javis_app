# JAVIS Home

iOS-first Flutter Home OS prototype in the Calm Ambient visual style.
Toolchain: Flutter 3.47.0 / Dart 3.13.0. Bundle ID: `com.javis.home`.

## Run

```sh
flutter pub get
flutter devices
flutter run -d <ios-simulator-id>
```

Xcode and an installed iOS Simulator runtime are required. A physical iPhone
also needs a development team/signing configuration in Xcode. No API,
database, or Tuya credentials are needed for this prototype.

To run the unavailable-state Tuya foundation on a connected physical iPhone:

```sh
flutter devices
flutter run -d <physical-iphone-device-id> \
  --dart-define=JAVIS_LIGHTING_PROVIDER=tuya
```

The checked-in native bridge deliberately contains no Tuya SDK and reports
`sdkUnavailable` on a physical iPhone (`unsupportedSimulator` in Simulator).
Live pairing requires the app-specific SmartLife iOS SDK v7.8.0 package and
matching security component. See `ios/TuyaIntegration.example.md`; never add
those private artifacts or credentials to Git.

## Demo walkthrough

1. Open Home; explore the featured living room and lighting controls.
2. Open a light; change power, brightness, white temperature, or color.
3. Browse Rooms, including the empty Kitchen and offline reading light.
4. Apply a scene to available demo lights.
5. Tap +, start demo pairing, and add a sample bulb. Enable failed-search preview
   to demonstrate retry. Repeating pairing does not add duplicate bulbs.

Changes are local to the app session and reset on restart. Pairing is simulated;
no real device is connected. AI is a future feature represented only by an
informational entry point.

## Launch, adaptive layout and language

Startup uses a static, appearance-aware iOS launch screen followed by a short
Flutter orbital animation. Both share the Calm Ambient paper, sage and gold
palette so the handoff does not flash white. Reduce Motion receives a shorter
fade. The launch sequence does not block lighting service initialization.

Tap the language control in any screen header to open the Calm Ambient language
sheet and choose English or Thai. All prototype labels, status messages, scene
descriptions and demo room/device names switch immediately; current navigation
and lighting/pairing state remain intact. The initial language follows the
device's preferred supported language, falling back to English. Manual selection
lasts for the current session and resets to device preference after a cold
restart.

Portrait iPad content is centered within a 704-point page width. At widths of
1000 points and above, Home and Scenes use two balanced columns and Rooms
uses a two-column list, within a maximum 1168-point page width. Detail and
pairing pages keep their readable width. Large accessibility text uses the
single-column layout. Room artwork maintains a 1.7:1 aspect ratio on all sizes.

The bilingual typed catalog is in `lib/core/localization/app_localizations.dart`.
Flutter's SDK localization delegates translate standard Material/Cupertino
controls. Add both translations together; do not translate future user-created
names through the demo-name helpers.

Thai uses bundled Noto Serif Thai headings and Noto Sans Thai body/controls,
with spacing for Thai marks. English uses Georgia headings and system body text.
Fonts load offline; sources and SIL Open Font Licenses are in `assets/fonts/`.

## Code and specs

- `lib/app.dart`: composition, injected service, system light/dark theme.
- `lib/core/`: Calm Ambient theme and shared visual primitives.
- `lib/features/home/`: dashboard and scene overview.
- `lib/features/rooms/`: room overview and detail.
- `lib/features/lighting/`: lighting model/service boundary and controls.
- `lib/features/pairing/`: simulated add-device journey.
- `specs/001-ios-calm-ambient-prototype.md`: scope and acceptance criteria.
- `specs/002-adaptive-layout-and-thai-english.md`: responsive layout, language
  switching, session behavior and verification.
- `specs/003-thai-typography-and-iphone-simulator.md`: Thai fonts and iPhone
  simulator preview.
- `specs/004-tuya-real-device-foundation.md`: real-device provider contract,
  external prerequisites, safety constraints and verification status.
- `specs/005-calm-language-sheet-and-splash.md`: themed language sheet, native
  launch handoff, Flutter motion, accessibility and verification.

Read AGENTS.md and the root engineering guide before changes. Create a spec
for every material task. Keep the architecture small and service interfaces
explicit; the hardware milestone will add a native Tuya iOS adapter.

## Verify

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```
