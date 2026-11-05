# Adaptive iPad layout and Thai/English

Status: Implemented — automated checks passed
Last updated: 2026-10-18

## Context

The phone layout fills the iPad width, stretching room artwork and controls.
The demonstration also needs a Thai/English switch usable inside the app.

## Goal

Keep Calm Ambient while giving tablets intentional content widths and balanced
columns, and localize every app-owned label, message and accessibility label.

## Non-goals

Real device/API integration, persistent language preference, other languages,
translation of future user-authored names, and a new navigation/state framework.

## User flow

- Open Home on a phone, portrait iPad or landscape iPad. Compact screens stack
  content; wide screens arrange related sections in balanced columns.
- Tap the visible language control and choose English or ไทย. The entire route
  tree updates immediately while tab, pairing and local lighting state remain.
- The first locale follows the device (Thai or English; other locales use
  English). A manual selection lasts for this app session.

## Acceptance criteria

- Home, Rooms, Scenes, room detail, light detail and pairing use bounded,
  centered readable content and safe areas. Room artwork keeps its proportions.
- Wide Home/Rooms/Scenes use columns when enough width exists; phone stays
  single-column, including with large accessibility text.
- Thai/English control is visible in the shell and on detail/pairing routes.
- All app-owned text, navigation, tooltips, status, failure/retry/success, demo
  explanations, scene names and demo room/device names have both translations.
- Material/Cupertino framework strings use Flutter localization delegates.
- Switching locale preserves device state and does not repeat pending actions.

## Implementation notes

Use a small typed bilingual catalog with a LocalizationsDelegate, plus the
Flutter SDK's flutter_localizations for native framework strings. Keep locale
at JavisApp composition level and expose the switch through an inherited scope.
Keep stable device IDs and room keys independent of translated presentation.
Shared adaptive scroll/column widgets bound widths without adding dependencies.
Keep decorative artwork at a fixed 1.7:1 aspect ratio so furniture cannot
stretch with viewport width. Portrait pages cap at 704 points including margins;
wide pages cap at 1168 points and switch columns at viewport width 1000.
Accessibility text above approximately 1.375× returns to one column.

## Risks

Long Thai labels and accessibility text need wrapping and scrollable layouts.
System fonts provide Thai fallback; physical-device typography review remains.
Session language resets to device preference on cold restart. Future stored
household/device names must remain verbatim rather than pass through the demo
translation catalog.

## Verification

Completed on 2026-10-18:

- Flutter SDK dependency resolution succeeded offline (`flutter pub get --offline`).
- `dart format --output=none --set-exit-if-changed .`: passed, 12 files unchanged.
- `flutter analyze`: passed, no issues.
- `flutter test`: passed, 8 widget tests covering existing navigation/control,
  failure/retry/success and duplicate prevention; portrait/landscape iPad widths,
  columns and image ratio; runtime Thai↔English across nested routes while
  preserving light state; locale switching during discovery; Thai device locale
  and dark theme at 2× accessibility text on a 390-point phone and wide iPad.
- `plutil -lint ios/Runner/Info.plist`: passed.

The installed SDK cache needs approved access outside the project. Initial
sandboxed tool invocations could not write its engine stamp; approved commands
then ran successfully. No physical iPad or native VoiceOver review was performed.

## Current status

Implemented all prototype screens with localized copy and accessibility labels,
a visible language menu on every route, framework localization delegates and
iOS supported-language declarations. State remains session-only and no real
device commands or API requests were introduced. No changes to API contracts.
