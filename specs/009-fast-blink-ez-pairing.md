# Fast-blink Wi-Fi EZ pairing

Status: Implemented behind local opt-in; Apple multicast approval/signing pending  
Last updated: 2026-10-18

## Context

The purchased Wi-Fi-only bulb repeatedly enters fast-blink pairing mode after
the user follows its five-cycle reset sequence. No slow-blink AP mode or
`SmartLife` hotspot has been observed. JAVIS currently offers only AP/AP+
pairing, so its discovery-first screen cannot find this bulb. Tuya documents
fast blinking as Wi-Fi EZ/SmartConfig pairing: the iPhone stays on the home
network while the SDK broadcasts network credentials and a pairing token.
Apple restricts broadcast/multicast traffic on physical iOS devices behind
the approved `com.apple.developer.networking.multicast` entitlement. The user
does not currently have, or is unsure about, a paid Developer Program team;
approval for this App ID is therefore not established.

## Goal

Add a Calm Ambient EZ pairing path for fast-blinking bulbs, using the existing
Tuya service boundary, token lifecycle, real-device success semantics, Thai/
English copy, and safe cancellation. Make signing/entitlement limitations
visible rather than implying a successful physical pairing.

## Non-goals

- Circumventing Apple's entitlement or using private Wi-Fi APIs.
- Auto-reading the home Wi-Fi password or showing a fabricated list of nearby
  networks on iOS.
- Replacing JAVIS with Tuya's vendor UI, changing Go/PostgreSQL, or claiming
  device control before the paired bulb's DP schema is verified.
- Submitting an Apple entitlement request or changing the user's signing team
  without separate authorization.

## User flow and bridge contract

1. The add-device screen offers clear fast-blink (EZ) and slow-blink (AP)
   choices. Fast-blink is the relevant path for this bulb; the AP flow remains
   available for other devices.
2. With the iPhone on a 2.4 GHz home network, prefill the current SSID when
   iOS permits, otherwise accept manual SSID entry. Ask for the password, then
   prepare a Tuya token while internet access is available. Never persist or
   log the password. Reject a known mismatch between the chosen SSID and the
   iPhone's current Wi-Fi; if iOS withholds the current name, honor the user's
   explicit entry and show the home-network reminder.
3. Keep EZ disabled by default. Native code requires an explicit `EnableEZ`
   opt-in in the ignored local Tuya configuration before starting EZ. The
   developer may set it only after Apple has approved multicast for the App ID
   and a signed build/profile has been independently checked. If not opted in,
   show an actionable entitlement-required state and do not attempt broadcast
   pairing. Do not add an unauthorized entitlement to the project's signed
   entitlements file. The public iOS SDK does not expose a supported in-app
   API to inspect the process's effective entitlements, so the app must not
   claim it verified the signature at runtime.
4. When available, start Tuya `ThingActivatorModeEZ` through the existing
   `startPairing` bridge using an explicit `mode: ez`. The phone remains on the
   home Wi-Fi. Success requires a Tuya activation callback plus home refresh.
   Existing operation IDs, timeout, cancellation and stale-callback guards
   apply to both modes.

The native `startPairing` bridge gains `mode: ez` alongside `mode: ap`; a
provider-neutral `pairingCapabilities` method returns whether the local EZ
opt-in is configured and, if not, a non-secret reason code. This does not
prove that the signed app has Apple approval; a signed/profile check remains
mandatory before enabling it.

## Acceptance criteria

- Fast-blink users are not sent to a bulb hotspot search.
- Real EZ activation is attempted only after explicit local post-approval
  opt-in; its absence produces a specific, bilingual explanation. iOS remains
  the final enforcer of the restricted entitlement.
- Passwords remain transient; cancel/retry cannot revive stale token or
  activation results. Demo mode stays separate.
- Existing AP/AP+ flow and tests continue to work.
- Flutter formatting, analysis, tests and an unsigned iOS device build pass.
  Physical EZ activation is reported pending until the Apple capability and
  the purchased bulb can be verified on a signed iPhone build.

## Implementation notes

- Tuya's iOS SDK documents `startConfigWiFi(.ez, ssid:password:token:timeout:)`
  and `stopConfigWiFi()` for cancellation. Reuse the native activator already
  retained for AP, with no vendor model leaking into Dart.
- Apple's restricted multicast entitlement requires Apple approval and must
  be in the provisioning profile and signed app, not merely named in source.
  A local `EnableEZ` flag is deliberately false/absent by default; check the
  signed binary/profile with Apple's documented tooling before setting it.
  Local Network permission text is already present; verify suitability.
- Official references:
  - https://developer.tuya.com/en/docs/app-development/ios-saas-commercial-lighting-ez?id=Kampptkrxg65o
  - https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.networking.multicast
  - https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy

## Risks

- The current Apple development team may not have multicast approval. In that
  case this implementation cannot be validated on a real iPhone until Apple
  grants it and the app is signed with the updated profile.
- EZ is less reliable than AP on some iOS/router combinations and still needs
  a 2.4 GHz Wi-Fi network.
- This exact bulb's Tuya account/product compatibility remains unverified.

## Verification

- Flutter format check, analyzer, and 40 tests passed, including EZ gating,
  no-hotspot EZ flow, cancellation, and success simulation.
- iOS profile device build without codesigning passed after the EZ SDK call
  and manual-SSID review fix. The example configuration, app Info.plist, and
  current entitlements passed `plutil -lint`.
- Physical EZ activation remains untested and cannot be claimed until Apple
  approves multicast for `com.javis.home`, the app is correctly signed, and
  the user tests the purchased bulb.

## Current status

The bulb was initially observed only in fast-blink mode. A later physical-iPhone
attempt reached a device Wi-Fi hotspot and paired through an AP-family path,
and the user reports it still blinked quickly. Blink speed alone did not
identify the pairing protocol for this bulb; the exact AP variant was not
captured. This does not establish EZ activation. JAVIS now defaults to a
custom fast-blink setup view, retains AP/AP+ as an explicit alternative, and
keeps the EZ activation path disabled unless `EnableEZ` is set in the ignored
local Tuya configuration after verified Apple approval/signing. The user has
not confirmed a paid Apple Developer Program account, so no real-bulb EZ
activation has been observed.
