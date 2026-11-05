# Remove a paired light

Status: Implemented; physical unbinding and re-pairing not yet verified
Last updated: 2026-10-18

## Context

The purchased bulb is paired in the JAVIS Tuya home and physical on/off works. The user wants to remove its pairing and try the setup journey again. The existing `cancelPairing` only stops an in-progress attempt; it does not unbind an already paired device.

## Goal

Let a user explicitly remove one already paired real light from the current Tuya home, then offer the existing add-device journey again. Keep the screen Calm Ambient and Thai/English localized.

## Non-goals

- Automatically removing the user's bulb during development or tests.
- Factory-resetting every setting or deleting the JAVIS home/account.
- Unpairing demo lights, supporting shared-home permissions, or guaranteeing the bulb enters a particular blink mode.

## User flow and bridge contract

1. A real light detail page offers a secondary “Remove light” action, even when the light is offline. Demo devices do not show it.
2. A themed confirmation sheet names the light, explains that control will stop, and asks the user to put the bulb in pairing mode before reconnecting. It does not insist on slow blinking: the user's previous successful setup joined the bulb Wi-Fi despite fast blinking. Cancel leaves the device untouched.
3. Confirm invokes `LightingService.removeDevice(deviceId)`, which sends `removeDevice` on the existing method channel. Native validates current session, home membership and device identity, then calls the Tuya device `remove` API.
4. Only a provider success removes the light from the client snapshot and returns to the previous page. A provider failure keeps the light visible and shows a localized retry error. Repeated taps/concurrent commands are rejected while removal runs.
5. The existing “Add device” flow is used for reconnecting. JAVIS does not silently launch pairing or claim the bulb is ready until it is actually discovered.

## Acceptance criteria

- Removing a real bulb requires an explicit second confirmation; dismiss/cancel makes no native call.
- Demo mode and invalid provider cannot invoke real removal.
- Native removes only the specified device in the current home, never the home or other devices, and reports an error instead of hiding it if Tuya fails.
- Successful removal updates the UI without restarting the app; stale local snapshots cannot reintroduce the removed device before the provider home refresh confirms it.
- Existing real on/off and pairing flows remain intact.
- All new app-owned labels and errors are in Thai and English.

## Implementation notes

- Tuya's `ThingSmartDevice.remove(success:failure:)` is distinct from `resetFactory`. Keep vendor SDK types behind the native bridge.
- Put the focused confirmation UI in its own lighting widget file; do not add another large flow to `light_detail_screen.dart`.
- Do not impose a hard line-count rule in `AGENTS.md`; split files and functions by responsibility and readability.
- The user's physical pairing corrected an earlier assumption: the bulb still
  blinked quickly when iPhone joined its device Wi-Fi and pairing succeeded.
  Pairing choices and guidance therefore name the network path (home Wi-Fi/EZ
  versus bulb Wi-Fi/AP), not blink speed as a prerequisite.

## Risks

- After removal, the bulb's next pairing state is unverified. The prior iPhone run joined a device Wi-Fi network while the user observed fast blinking, which supports an AP-family path but does not prove its exact variant. Do not equate blink speed alone with AP/EZ or promise reconnection. The dedicated EZ path remains gated by Apple's multicast entitlement.
- A removal callback or home list can race a DP event or cached snapshot. Guard duplicate requests and keep the removed ID hidden until a fresh home membership snapshot confirms deletion.
- A signed app on the user's iPhone and user action are needed to verify physical unbinding; automated tests must never remove the real bulb.

## Verification

- `dart format --output=none --set-exit-if-changed .`: passed; 17 files, 0 changes.
- `flutter analyze`: passed with no issues. A parallel run initially collided with a Flutter-generated iOS ephemeral file; the sequential rerun passed.
- `flutter test`: all 46 tests passed, including provider success/failure and duplicate-command protections plus confirmation cancel/confirm and demo exclusion.
- `flutter build ios --debug --no-codesign`: passed for iPhone device target. It does not install or sign the app.
- After correcting the blink-speed assumption and renaming the setup choices,
  the format check, analyzer and all 46 Flutter tests passed again. The native
  AP/EZ methods were unchanged in this follow-up.
- Physical removal and re-pairing are deliberately not automated; the user must confirm the action on the iPhone after installing the new build.

## Current status

The real light detail page now has a separate Calm Ambient confirmation sheet.
The provider-neutral Dart service and native bridge call Tuya's device `remove`
only after confirmation. On success the device disappears from the snapshot;
on failure it remains and the user sees a localized error. Native guards
duplicate removal/command races and temporarily suppresses stale device-list
snapshots until the device is paired again. Existing demo and active-pairing
paths are unchanged. iOS compilation and automated tests pass; physical
unbinding and re-pairing remain for user verification.
After the user's correction, the confirmation and add-device copy no longer
require slow blinking; they direct the user to check for bulb Wi-Fi even if
the light blinks quickly. The actual AP/EZ native methods were not changed.
