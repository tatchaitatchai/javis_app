# Theme switch

Status: Implemented; VoiceOver and a real iPhone not yet checked
Last updated: 2026-11-05

## Context

The app ships a light and a dark Calm Ambient theme and always follows the iPhone
setting (`ThemeMode.system`). The Theme row on the profile screen only states this
and cannot be changed. The owner wants to switch theme inside the app.

## Goal

Let the user choose System, Light or Dark on the profile screen, apply it at once,
and keep the choice between launches.

## Non-goals

- More themes or custom colors.
- Syncing the choice between devices or storing it in the API. It is a preference
  of this device, so it stays after sign-out.
- Keeping the chosen language between launches.
- Android storage. The native side exists on iOS only; other platforms fall back
  to System.

## User flow

1. Profile tab > Usage section > Theme shows a three-way control: System, Light,
   Dark. A new install starts on System, which is today's behavior.
2. Tapping an option recolors the whole app with a short fade, or instantly under
   Reduce Motion.
3. The app reopens on the same choice from the first Flutter frame.

## Acceptance criteria

- [x] The control offers System, Light and Dark, in Thai and English.
- [x] The choice applies to every screen at once, including ones under the sheet.
- [x] The status bar stays readable when the choice differs from the iPhone setting.
- [x] The choice survives a restart. Sign-out does not touch it: the mode is held
      outside the account stores (read from the code, not run).
- [x] A missing, unknown or unreadable stored value falls back to System.
- [x] Labels do not clip or break mid-word at 2x text.
- [ ] VoiceOver reads the options and the selected state (not checked).

## Implementation notes

- `lib/core/theme/app_appearance.dart`: `ThemePreference` (read and write the
  choice), `DeviceThemePreference` (channel `com.javis.home/theme`), and the
  `AppAppearance` inherited widget, shaped like `AppLanguage`.
- `ios/Runner/ThemePreferenceBridge.swift`: UserDefaults, no new package. The value
  is not sensitive, so it does not belong in the Keychain.
- `_JavisAppState` owns the current mode. `main` reads the stored choice before
  `runApp`, so the first Flutter frame is already correct.
- `MaterialApp.builder` sets the status bar style from the applied theme, because
  iOS would otherwise follow the system setting.
- The fade is `MaterialApp`'s `AnimatedTheme`, using the `Motion` tokens.
  `CalmPalette.lerp` already supports it.
- `CalmSegment` labels scale down instead of wrapping, so long labels stay whole
  at large text sizes.
- `CalmSegment` keeps the selected option enabled. It used to pass a null callback,
  which made `Pressable` dim the selected label to 45%. This also fixes the language
  control and the other segments.

## Risks

- The native launch screen follows the iPhone setting because iOS draws it before
  the app runs, so a user who picks the opposite theme sees it briefly at launch.
  Seen on the Simulator: a dark launch, then the light app.
- `main` depends on the native channel being registered before the first read. A
  failed read falls back to System and is logged.

## Verification

- `dart format`, `flutter analyze` and `flutter test` pass, including
  `test/theme_switch_test.dart`. The live API test was skipped.
- iOS Simulator (iPhone 15 Pro, iOS 17) with the iPhone set to dark, against the
  local API: chose Light and the app and status bar turned light; rebuilt and
  reopened and it stayed light; chose Dark; chose System, then switched the
  Simulator to light and the app followed. Checked Thai and English in light and
  dark, and Thai at `accessibility-large` text.
- Not checked: VoiceOver, Reduce Motion, tap feel on a real iPhone, and an actual
  sign-out with a stored choice.
