# JAVIS Flutter guide

Read ../AGENTS.md, ../PROJECT_SPEC.md, and the relevant specs/ Markdown first.
Every material change needs a spec before code, updated with actual verification.

The client is iOS first. Keep com.javis.home and JAVIS Home unless a product
decision changes them. Use Calm Ambient: warm paper, sage, generous space,
quiet typography, restrained decoration, and clear controls.

Organize by feature under lib/features/. Keep shared theme tokens in
lib/core/theme/ and reusable visual primitives in lib/core/widgets/.
If a screen or service becomes difficult to read, extract cohesive UI sections
or provider operations into plainly named feature-local files. Keep state and
flow ownership obvious; use short helpers for one task, not a rigid line-count
rule or a new architecture just to make a file look shorter.
Current state uses an injected LightingService and Flutter ChangeNotifier.
Do not introduce state/routing packages or generic architectural layers without
a demonstrated need. Native Tuya SDK code belongs behind a platform adapter;
presentation must not depend on vendor types or credentials.

Real-device groundwork is defined by
`specs/004-tuya-real-device-foundation.md`. Demo is the default provider;
`--dart-define=JAVIS_LIGHTING_PROVIDER=tuya` selects the channel-backed provider
and must never fall back to demo devices. Preserve operation IDs, transport
cancellation, session-generation checks, capability-driven controls, and the
method/event channel contract when adding the private SDK. Local Tuya packages,
security components and configuration stay in the ignored paths documented by
`ios/TuyaIntegration.example.md`; never add them or their values to source.

Respect safe areas, system brightness, Dynamic Type, semantics, 48-point touch
targets, and reduced motion. Keep content scrollable at large text sizes.
Preserve loading, offline/empty, error/retry, success, and duplicate protections.
Never imply local demo changes operate a physical device. No credentials or
real household/device identifiers may be committed.

Use the typed AppLocalizations catalog in lib/core/localization/ for app-owned
messages and accessibility labels; add English and Thai together. Keep demo
translation keys separate from identifiers and never translate user-authored
device names. Locale selection is session-scoped at JavisApp. Use AdaptivePage
for scrollable page content and retain RoomArtwork's fixed aspect ratio. Wide
layouts may use CalmColumns; large text falls back to one readable column.
Keep locale-specific typography in the shared theme: bundled Noto Serif Thai
headings/Noto Sans Thai body for Thai, Georgia/system for English. Preserve font
licenses in assets/fonts/ and avoid network-dependent font loading.

The startup contract is defined in
`specs/005-calm-language-sheet-and-splash.md`. Preserve the appearance-aware
native `LaunchScreen.storyboard` and named colors as the immediate static frame,
then `LaunchExperience` as the finite Flutter handoff. Do not add network or
video splash dependencies, replay the splash on locale changes, or delay
lighting-service initialization. Widget tests that are unrelated to startup
should construct `JavisApp(showSplash: false)`.

Before handoff run dart format --output=none --set-exit-if-changed ., flutter
analyze, and flutter test. Record limitations in the task spec. Request SDK-cache
access when the installed Flutter toolchain needs it; do not alter unrelated SDK
or system settings. Do not commit, push, deploy, or configure signing unless asked.
