# App icon: Home glow

Status: Implemented; iOS 18+ dark/tinted icon appearances and a fresh-install launch snapshot not yet verified
Last updated: 2026-11-01

## Context

The iOS app still ships Flutter's default app icon. Five logo directions were
explored for JAVIS Home; the owner chose concept A, "Home glow": a house-shaped
doorway outline with a warm gold light inside it. It ties the brand to the first
vertical slice (a smart bulb) and to the Calm Ambient palette in
`lib/core/theme/calm_palette.dart`.

## Goal

Replace the default iOS app icon with the Home glow mark, including the iOS 18
dark and tinted appearances, and keep vector masters so the mark can be reused
for a wordmark, store assets and later platforms. Then carry the same mark into
the two-stage launch experience (native launch screen and Flutter splash) so
the icon and the first screen read as one brand.

## Non-goals

- Changing splash timing, the wordmark, the product line, reduced-motion
  behaviour or the splash gate contract defined in spec 005.
- The unused Flutter `LaunchImage.imageset` placeholder.
- Android, web or macOS icons.
- An Icon Composer (`.icon`) Liquid Glass layered icon. The asset-catalog icon
  remains the shipped source for now.
- Changing the bundle identifier, display name or signing.

## Design

- Canvas 1024 x 1024, full bleed, opaque, no pre-rounded corners (iOS applies
  the mask).
- Mark: an open-bottom house outline (two walls and a pitched roof) in paper
  `#FBFAF5`, round caps and joins, with a gold `#E3C68C` light centred low
  inside it and two flat translucent halos.
- Default (light) appearance: ink background `#253026`.
- Dark appearance: dark canvas `#151A15`, the outline in `#EDF0E8`, same gold.
- Tinted appearance: grayscale on black; iOS applies the user's tint.
- Vector masters live in `../Design/brand/` (repository root `Design/brand/`):
  `javis-home-icon.svg`, `javis-home-icon-dark.svg`,
  `javis-home-icon-tinted.svg`, `javis-home-mark.svg` (mark only, transparent)
  and `javis-home-lockup.svg` (mark plus "JAVIS Home" wordmark).

## Splash

- The launch motif box is 200 pt (was 248 pt) so the house sits closer to the
  wordmark. Native now centres it 52 pt above the safe-area centre (was the
  view centre) and places the wordmark 33 pt below it (was 30 pt). This removes
  a pre-existing handoff jump: Flutter centres the splash in the safe area, and
  on iPhone 15 Pro the native frame sat about 12-16 pt higher than Flutter's.
  The wordmark and product-line text are unchanged.
- The house is drawn at 0.3 pt per SVG unit (about 131 pt wide), centred on
  the house's visual centre (SVG point 512, 515), with a lighter 44-unit stroke
  (13 pt) than the icon's 60 units so it sits quietly beside the thin wordmark.
- Light: ink outline (`CalmPalette.text`, `#253026`) with a `goldDeep`
  `#C9A962` light. Dark: outline `#EDF0E8` with `gold` `#E3C68C`.
- Native: one `UIImageView` showing the `LaunchMark` image set (1x/2x/3x PNGs
  with dark-appearance variants) rendered from `Design/brand/javis-home-launch*.svg`.
- Flutter: `_HomeGlowPainter` draws the same geometry so its first frame matches
  the native frame. The light then swells: the two halos grow and brighten and
  ease back while the splash fades out, like a lamp coming on. Reduced Motion
  draws the static mark only.

## Welcome screen

- The Welcome hero uses the same mark. The painter now lives in the shared
  `lib/core/widgets/home_glow_mark.dart` (`HomeGlowMark`), used by both the
  splash and `WelcomeScreen`; the old sage-ring `JavisOrb` was removed (it had
  no other users). The hero keeps the old 152 pt footprint so the layout and
  the onboarding tests that tap the footer button are unchanged.

## Acceptance criteria

- `ios/Runner/Assets.xcassets/AppIcon.appiconset` contains a single-size
  1024 px universal icon plus dark and tinted variants, and no Flutter default
  artwork.
- PNGs are 1024 x 1024 and opaque.
- The mark stays recognizable at 29 pt (Settings) and 40 pt (Spotlight).
- The iOS build compiles the asset catalog without icon warnings, and the
  simulator home screen shows the new icon.
- The native launch frame and the first Flutter splash frame show the same mark
  at the same size and position, in light and dark appearance.
- Existing launch tests (splash completes once, reduced motion) still pass.

## Implementation notes

- PNGs are rasterized from the SVG masters with headless Google Chrome
  (`--headless=new --screenshot`), then flattened to opaque 8-bit PNGs with
  ImageMagick. ImageMagick's built-in MSVG renderer was rejected: it dropped
  the stroked outline and mis-rendered letter spacing. No project dependency
  was added.
- The single-size asset-catalog format lets Xcode derive every smaller size.
  The deployment target (iOS 15) is supported by this format; dark and tinted
  variants only appear on iOS 18 and later.
- The replaced Flutter default PNGs were moved out of the project to a
  temporary session backup, not committed anywhere (the workspace is not a git
  repository).
- `LaunchAmbientWash`, `LaunchSage` and `LaunchGold` colour sets are no longer
  referenced by the storyboard. They were left in the asset catalog.
- Launch text now matches at the handoff. Native shows plain-text labels
  "J A V I S" and "Your home, in harmony" (12 pt regular, 19 pt below the
  wordmark), with `th.lproj/LaunchScreen.strings` supplying the Thai product
  line. Flutter draws "J A V I S" (semantics label "JAVIS") with -1.35 letter
  spacing and the product line with -0.09 in English (no change in Thai);
  these offsets compensate for UIKit tracking SF tighter than Flutter and were
  measured on the iOS 17 simulator. `LaunchInk`, `LaunchSecondaryInk` and the
  dark `LaunchBackground` now use the exact `CalmPalette` values.
- Attributed text (`NSKern`) in the launch storyboard was tried and rejected:
  `ibtool` compiled it without warnings but dropped the text from the nib, and
  attributed labels cannot be localized through a strings file.

## Risks

- Tinted-icon rendering is controlled by iOS; the grayscale variant may need
  contrast tuning after viewing it on a device.
- The lockup SVG uses live text (Georgia), so it renders with a fallback font
  where Georgia is missing. Outline the text before using it in print or store
  artwork.

## Verification

2026-11-01:

- `AppIcon.png` and `AppIcon-Dark.png` are 1024 x 1024 opaque sRGB;
  `AppIcon-Tinted.png` is 1024 x 1024 opaque grayscale.
- Downscaled previews at 180, 120, 87 and 58 px kept the house and light
  legible.
- `flutter build ios --simulator --debug` succeeded. The built `Runner.app`
  contains `Assets.car`, `AppIcon60x60@2x.png` and
  `CFBundleIconName = AppIcon`.
- On the `JAVIS iPhone 15 Pro iOS17` simulator (iOS 17.0) the home screen shows
  the new icon labelled "JAVIS Home".
- `dart format --output=none --set-exit-if-changed .`: 0 changed;
  `flutter analyze`: no issues; `flutter test`: all 53 tests passed.
- Splash: `xmllint` and `xcrun ibtool --compile` accepted the storyboard; the
  built `Assets.car` contains `LaunchMark` at 1x/2x/3x for any and dark
  appearance; format, analyze and all 53 tests passed after the Flutter change.
- Splash on the iOS 17 simulator, light and dark: the native frame shows the
  mark; measured at 3x, the house top is at 645 px native vs 643 px Flutter and
  the wordmark at 1281 px vs 1279 px (under 1 pt). Flutter frames show the halos
  swelling and settling before the fade.
- Simulator quirk seen: the launch snapshot iOS generated during the first
  install logged `Could not load the "LaunchMark" image` and showed no mark,
  even after a simulator reboot. After moving the app's
  `Library/SplashBoard` cache aside, the regenerated snapshot showed the mark
  on every launch. Cause unverified; check a fresh install on a real device.
- Launch text, English, light and dark, measured at 3x: wordmark width 318 px
  native vs 317 px Flutter (left edge 430 vs 432 px); product line 386 px vs
  381 px wide, same baseline. Format, analyze and all 53 tests passed.
- Welcome: format, analyze and all 53 tests passed; on the iOS 17 simulator in
  dark mode the Welcome hero shows the Home glow mark. A first attempt at
  168 pt pushed the footer button off the 800 x 600 test viewport and failed
  two onboarding tests, so it stays 152 pt.
- Not verified: the Thai launch frame (needs the simulator language switched
  to Thai); Flutter renders Thai in Noto Sans Thai while native uses the iOS
  system Thai font, so the Thai line cannot match glyph for glyph.
- Not verified: the dark and tinted icon variants, which need iOS 18 or later;
  the Xcode build log was filtered for asset/launch warnings (none) but not
  reviewed line by line; launch layout on devices other than iPhone 15 Pro.
