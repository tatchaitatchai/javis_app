# Calm language sheet and launch experience

Status: Complete
Last updated: 2026-11-01

## Context

The current language selector is Flutter's default rectangular popup menu. Its
sharp surface, generic elevation and sparse rows visibly conflict with JAVIS's
rounded Calm Ambient visual system. The iOS launch storyboard is also the
default white screen with a transparent placeholder, so startup does not express
the product identity and can flash before Flutter renders.

## Goal

Replace the language popup with a polished Calm Ambient selection sheet and add
a cohesive two-stage launch experience: an instant native iOS launch screen
followed by a short, refined Flutter motion sequence. Startup should feel
spatial, premium and slightly futuristic without becoming loud or slowing access
to the home.

## Non-goals

- A new logo, app icon, onboarding flow, authentication gate or persistent
  language preference.
- Video, network-loaded media, third-party animation packages or generated
  splash-screen dependencies.
- Long, blocking or unskippable animation.
- Android launch-screen work in this iOS-first milestone.

## User flow

1. iOS immediately presents the warm JAVIS native launch composition while the
   Flutter engine starts, with no white placeholder flash.
2. Flutter continues the same composition with restrained orbital light motion,
   the JAVIS wordmark and product line, then reveals Home automatically.
3. Reduce Motion users receive a short cross-fade without rotation or sweeping
   movement.
4. Tapping the language control opens a rounded bottom sheet with a handle,
   localized title, generous English/Thai rows and a clear selected state.
5. Selecting a language closes the sheet and updates the current route without
   resetting navigation, lighting or pairing state.

## Acceptance criteria

- The default popup menu is removed; the selector uses Calm colors, 24+ point
  top corners, restrained barrier/elevation and 48+ point touch targets.
- Both English and Thai rows expose selected semantics and remain readable at 2×
  text scale, in light/dark themes and above the safe area.
- Dismissing the sheet without a choice changes no locale or app state.
- Native launch background/wordmark visually match the first Flutter splash
  frame and support light/dark appearance without third-party assets.
- Flutter splash completes in roughly 1–1.6 seconds, can be disabled explicitly
  in tests, does not reappear on locale changes, and preserves provider
  initialization/state.
- The motion uses Flutter SDK animation/custom painting only, has no continuous
  ticker after completion and respects reduced-motion accessibility settings.
- Existing app navigation, localization, Tuya/demo provider selection and all
  regression tests remain intact.
- Simulator visual checks cover the splash composition and language sheet on an
  iPhone-size device.

## Implementation notes

- Keep `LanguageButton` as the reusable entry point on Home and detail routes;
  present a purpose-built modal bottom sheet rather than styling one global
  popup menu.
- Reuse existing Calm theme tokens. Use selection indicators and text rather
  than color alone.
- Add a small production splash gate around `HomeShell`; keep service
  initialization in `JavisApp` so startup work proceeds concurrently.
- Use a finite animation controller and `CustomPainter` for soft concentric
  arcs/orbs. Avoid large raster assets and preserve crisp rendering at all
  device sizes.
- Build the native launch screen from UIKit storyboard primitives and named
  appearance-aware colors so it remains immediate and deterministic.

- 2026-11-01: the orbital motif was replaced by the Home glow app-icon mark
  (spec 014). The native screen now shows a `LaunchMark` image asset with
  light/dark variants instead of glyph-based orbits, the motif box is 200 pt
  and is centred on the safe area to match Flutter, and the Flutter motion is the mark's light swelling rather than an orbiting
  satellite. The native wordmark and product line now match the Flutter text
  (localized via `th.lproj/LaunchScreen.strings`); timing and the splash gate
  are unchanged.

## Risks

- A launch composition that differs in scale or background from Flutter can
  create a visible handoff jump.
- Splash timing can make widget tests flaky unless tests opt out explicitly.
- Bottom sheets can overflow with large Dynamic Type unless content is scrollable
  or height-flexible.
- Native launch screens are static by platform design; animation belongs only in
  Flutter after the first frame.

## Verification

- `dart format --output=none --set-exit-if-changed .` passed with 16 files
  unchanged.
- `flutter analyze` passed with no issues.
- `flutter test` passed all 24 tests, including launch lifecycle, reduced-motion,
  large-text language sheet, selected semantics, dismissal and locale switching.
- Native launch resources passed `xmllint`, `jq` and
  `xcrun ibtool --compile` validation.
- `flutter build ios --simulator --debug` built
  `build/ios/iphonesimulator/Runner.app` successfully.
- Visual review passed on an iPhone 15 Pro / iOS 17 simulator for the native
  launch frame, Flutter animated handoff and Thai language sheet. Captures are
  available at `build/iphone-calm-splash.png`,
  `build/iphone-flutter-splash.png` and
  `build/iphone-calm-language-sheet.png`.

## Current status

Implemented and verified. The old rectangular popup is now a localized,
scroll-safe Calm Ambient bottom sheet with explicit selected semantics. Startup
uses an appearance-aware native iOS composition followed by a finite Flutter
orbital animation. Reduced Motion receives a short fade, and tests can disable
the splash without changing production behavior.
