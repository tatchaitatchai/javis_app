# iOS foundation and Calm Ambient prototype

Status: Implemented — automated checks passed
Last updated: 2026-10-18

## Context

JAVIS Home is an iOS-first Flutter Home OS. This milestone gives the project a
demonstrable UI before native Tuya integration and API-backed household data.
Read the root PROJECT_SPEC.md and AGENTS.md before this specification.

## Goal

Provide a polished, navigable Calm Ambient prototype for home overview, rooms,
lighting control, scenes, and a clearly simulated add-device journey.

## Non-goals

Real device discovery, Wi-Fi provisioning, Tuya credentials, accounts, network
requests, persistent storage, AI responses, and production automation.

## User flow

1. Open Home to a warm overview, a featured room, lighting, and scene shortcuts.
2. Browse Rooms and select a room to see its devices.
3. Open a light; change its power, brightness, white temperature, or color.
4. Add device: review requirements, run a simulated discovery, review the demo
   bulb, then add it to the local session. No Wi-Fi password is requested.
5. Visit Scenes to apply a local lighting preset. UI always identifies demo mode.

## Acceptance criteria

- iOS project keeps bundle ID com.javis.home and display name JAVIS Home.
- Dashboard, room list, room detail, device detail, and pairing flow are reachable.
- Local lighting changes remain consistent across screens for the session.
- Pairing and scenes cannot be mistaken for physical device operations.
- Pairing supports loading, simulated failure/retry, cancel, and success without
  duplicate additions; offline devices explain why controls are disabled.
- Warm neutral light and dark themes follow system preference; safe areas,
  readable contrast, semantic control labels, and large text are supported.
- No additional production packages are required.

## Implementation notes

Use feature-first Flutter files, shared theme tokens and small reusable widgets.
An injectable lighting service owns mock device state behind an app-facing
interface. Flutter Listenable/AnimatedBuilder is sufficient for this milestone.
Use native-feeling Cupertino route transitions with Material controls styled for
Calm Ambient. Add no repository, code generator, or routing framework.

## Risks

The prototype is session-only and does not establish real network or hardware
compatibility. Future Tuya integration needs a native iOS adapter, credentials,
real-device testing, and a separate specification. Offline and discovery failure
are demonstrable mock states, not transport diagnostics.

## Verification

Completed on 2026-10-18:

- `dart format --output=none --set-exit-if-changed .`: passed, 11 files unchanged.
- `flutter analyze`: passed, no issues.
- `flutter test`: passed, 3 targeted widget tests.
- Tests cover room-to-light navigation and power state, simulated discovery
  failure/retry/success and duplicate prevention, and dark theme at 2× text size
  through home, rooms, room detail, and lighting temperature controls.

The installed SDK cache is outside the workspace; checks used approved access
to that cache and the absolute Flutter/Dart tool paths. The shell PATH differed
under escalation, so the initial bare `dart` command was unavailable. Simulator
build/run verification is coordinated by the workspace owner separately.

## Current status

Implemented Home dashboard, room overview/detail (including an empty kitchen),
light detail with power/brightness/white temperature/color controls, scene
presets, offline-device handling, and simulated add-device preparation/search/
failure/retry/found/success flows. Adding the same sample bulb is idempotent.
The app follows system light/dark preference and uses scrollable safe-area
layouts with semantic labels and no custom continuous animation.

State is owned by an injected `LightingService`; `MockLightingService` holds
immutable demo devices for the current app session. UI files are feature-first,
shared lighting widgets live with lighting, and no production dependency was
added. Room artwork is a local decorative CustomPainter, requiring no external
image download. AI entry explains the future scope without simulating answers.

Live hardware pairing/control, API integration, persistence, physical-device
accessibility review, and iPhone signing remain future work.
