# Calm Ambient pairing experience

Status: Implemented
Last updated: 2026-10-18

This spec records the original guided AP presentation. The current screen also
includes the discovery-first journey and Wi-Fi chooser specified in
`008-discovery-first-pairing.md`; manual AP remains the fallback.

## Context

The initial add-device screen exposes the real Tuya AP flow, but the long list
of requirements, form, and actions reads like a setup checklist. The primary
action can sit below the fold on iPhone. The user wants a polished, familiar
consumer-app experience for the physical iPhone demo.

## Goal

Make pairing feel like a short guided journey within the existing Calm Ambient
system. Show one clear current step, a visible progress cue, concise guidance,
and a prominent action. Preserve the truthful AP sequence and demo behavior.

## Non-goals

- Changing Tuya SDK activation, credentials, home/account setup, or the native
  bridge contract.
- Claiming the bulb is discovered before the provider confirms it.
- Automatic Wi-Fi switching, background pairing, new UI packages, or a design
  system rewrite.

## User flow

1. A concise hero and three-step progress cue show whether the user is setting
   up the home, entering 2.4 GHz Wi-Fi, or joining the bulb hotspot. A local
   readiness issue stays visible with an appropriate retry/setup action.
2. The Wi-Fi step uses a focused form, a short slow-blink tip, and one primary
   button to prepare the short-lived pairing token while online.
3. The hotspot step shows numbered iPhone Settings instructions, token timing,
   and one button to connect after returning to JAVIS. Editing Wi-Fi remains
   available without losing the current screen.
4. Searching, failure/cancellation and success have distinct visual states and
   clear next actions. The user may cancel an active attempt and retry safely.
5. Demo mode keeps its simulation disclaimer and add-to-home confirmation.

## Acceptance criteria

- Phone layout has a clear hierarchy and a prominent action without oversized
  empty space. Content remains scrollable with large text and iPhone safe areas.
- Thai and English are complete for all new text; VoiceOver can read progress,
  status, fields and actions. Light and dark themes remain legible.
- The SSID/password stay transient. The password is masked by default and
  cleared at activation/retry. No new external package or network asset.
- The step sequence still calls `prepareHome`, `preparePairing`, then AP
  `startPairing`; cancellation and stale-result protection are unchanged.
- Existing behavioral tests pass, and targeted widget checks cover the visible
  AP steps and primary action availability.

## Implementation notes

- Keep this presentation in `features/pairing/` with small local widgets and
  shared Calm Ambient tokens. Do not move provider behavior into UI.
- Keep existing localized service errors. Use compact cards, numbered rows and
  a bottom action region appropriate for iPhone, with scroll fallback for
  Dynamic Type.

## Risks

- A sticky action can overlap the keyboard or system safe area; verify form
  focus and small-screen layout.
- Rewording AP instructions must not imply that fast blinking or a normal home
  Wi-Fi connection works at the hotspot stage.

## Verification

- `dart format --output=none --set-exit-if-changed .`: passed, 16 files unchanged
  after formatting.
- `flutter analyze`: passed with no issues.
- `flutter test`: all 28 tests passed. The AP widget test covers preparation,
  hotspot instructions, connection action, cancellation, retry and password
  clearing. Existing demo and localization tests still pass.
- `flutter build ios --profile --no-codesign
  --dart-define=JAVIS_LIGHTING_PROVIDER=tuya`: passed for physical iPhone target.
- Inspected the iPhone 15 Pro Simulator demo pairing screen at normal text size.
  Progress, hero, card and persistent action fit the phone safe area. The real
  Wi-Fi and hotspot steps still need a physical-device visual check after Tuya
  home setup succeeds.

## Current status

Implemented. The pairing screen now uses a three-step progress cue, compact
Calm Ambient hero, focused cards and a safe-area action bar. The real flow is
still blocked on physical bulb and Tuya cloud verification, as tracked in
`006-tuya-iphone-pairing.md`.
