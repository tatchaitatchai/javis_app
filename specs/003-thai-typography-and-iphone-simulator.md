# Thai typography and iPhone preview

Status: Complete
Last updated: 2026-10-18

## Context

The localized prototype relies on iOS fallback for Thai while its large headings
request Georgia. The result lacks the intentional typography of the English
Calm Ambient design. The current presentation should also run on an iPhone
simulator rather than the iPad used for the previous review.

## Goal

Give Thai a consistent, readable typography pairing and preview the application
on an iPhone simulator while retaining runtime language switching.

## Non-goals

New screens, hardware/API integration, persistent language preferences, changes
to the established adaptive layout, or a third-party font-loading dependency.

## User flow

1. Open the application in Thai or select ไทย from the language control.
2. See Noto Serif Thai in editorial headings and Noto Sans Thai in controls/body.
3. Switch to English; retain Georgia headings and system body typography.
4. Preview the same app on an iPhone simulator.

## Acceptance criteria

- Thai headings/body use locally bundled fonts with redistribution licenses.
- Runtime switching updates typography throughout the route tree without losing
  navigation or lighting/pairing state.
- Device locale resolution selects the same language for text and typography.
- Thai line spacing accommodates marks; phone screens remain scrollable with
  large accessibility text in light and dark themes.
- The iPhone simulator opens the built app; actual device/model and verification
  results are recorded here before handoff.

## Implementation notes

Bundle official Google Fonts Noto Serif Thai and Noto Sans Thai variable TTFs.
Keep the font choice and Thai spacing in the existing shared theme. Resolve
the effective locale at app composition, including device-locale changes when
the user has not chosen a language. Keep English typography unchanged.

## Risks

Thai marks and longer labels need real simulator visual inspection in addition
to widget checks. Bundled fonts increase the app size slightly. Simulator
preview does not replace physical-device or VoiceOver testing.

## Verification

Completed on 2026-10-18:

- `dart format --output=none --set-exit-if-changed .`: passed, 12 files unchanged.
- `flutter analyze`: passed, no issues.
- `flutter test`: passed, all 8 widget tests. Existing runtime language-switch
  coverage now also checks the Thai/English font pairing. Thai device locale,
  dark mode and 2× accessibility text continue to pass on phone/tablet layouts.
- Downloaded font assets were identified as valid TrueType files. Both original
  SIL Open Font Licenses and upstream source links accompany them.

The first sandboxed Dart invocation could not update the installed SDK cache;
formatting and checks succeeded using approved access.

- `flutter build ios --simulator`: passed and produced
  `build/ios/iphonesimulator/Runner.app`.
- Installed and launched `com.javis.home` in Thai on an iPhone 15 Pro simulator
  running iOS 17.0.
- Visual review confirmed correct Thai marks, visibly distinct heading/body
  families, no horizontal clipping and normal vertical scrolling.
- Review capture: `build/iphone-thai-home.png`.

## Current status

Implemented locale-specific fonts and Thai line spacing in the shared theme.
The app resolves its effective locale once for text and typography, follows
device-locale changes until a manual selection, and preserves existing
session/navigation state. Fonts are local assets, requiring no new dependency
or runtime download. English typography retains Georgia/system fonts.

The iPhone simulator preview is complete. No physical-device or native
VoiceOver review has been performed; those remain follow-up validation rather
than blockers for this prototype.
