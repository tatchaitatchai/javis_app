# Discovery-first Wi-Fi bulb pairing

Status: Implemented; physical pairing observed, AP/AP+ variant not recorded  
Last updated: 2026-10-18

Early attempts observed fast blinking and did not find an AP hotspot. A later
physical-iPhone attempt joined device Wi-Fi and paired successfully while the
user still observed fast blinking. Blink speed alone must not be treated as
proof of the protocol used. The separate EZ path is specified in
`009-fast-blink-ez-pairing.md`; this AP/AP+ flow remains available.

## Context

The purchased bulb is marked Wi-Fi-only on its box. Smart Life visibly lists
`Smart-Bulb-E27-wifi` as a nearby device before asking for a 2.4 GHz home
network. JAVIS currently implements legacy Tuya AP activation and asks for a
manually typed router SSID/password before the user joins the bulb hotspot.
The user wants to discover a bulb first, then choose a home network without
typing the SSID.

## Goal

Provide the closest truthful, supported iPhone flow to Smart Life: show only
provider-confirmed discovered devices, then present a Wi-Fi selection step with
the current network preselected when iOS permits. Keep legacy AP pairing as a
working fallback while support for this exact bulb is validated.

## Non-goals

- Inventing nearby devices, assuming Smart Life's internal discovery is exposed
  by the installed HomeKit SDK, or treating discovery as completed pairing.
- Reading saved iOS Wi-Fi passwords or scanning all nearby router SSIDs using
  private iOS APIs.
- Replacing the Calm Ambient app with an unthemed vendor screen without an
  explicit product decision.
- Claiming the physical bulb paired before the Tuya callback and home refresh.

## User flow and bridge contract

1. Prepare or reuse the demo Tuya home. Read the currently connected home
   SSID, when iOS grants access, before switching networks. Cache no password.
2. Obtain a short-lived Tuya pairing token while internet is available. Ask
   iOS to join an open hotspot with Tuya's documented `SmartLife` prefix,
   showing the required system confirmation. Verify that the iPhone actually
   joined a matching SSID before presenting a generic "device hotspot found"
   result. Do not claim the device is this particular bulb yet.
3. After the verified hotspot connection, use the Tuya AP+ session to request
   compatible Wi-Fi networks from the device. Show a chooser only for actual
   returned SSIDs; a prefilled home SSID absent from that list is cleared. The
   user enters the router password. Resume AP+ on the same SDK session only
   for a returned network. Show success only after its Tuya callback and home
   refresh.
4. If the bulb cannot return a list, clear any entered password, cancel the
   AP+ session, and instruct the user to reconnect to home Wi-Fi before
   preparing a fresh token for legacy manual AP pairing. The fallback never
   sends credentials to an unverified hotspot merely because its SSID begins
   with `SmartLife`.
5. If no matching hotspot is available, permission is declined, or verification
   fails, explain the result and offer the existing manual AP path. This is a
   fallback, not a fabricated scan result.
6. Preserve operation IDs, cancellation, stale-callback protection, token
   lifetime, and provider-confirmed success semantics.

Native bridge methods are `currentWifi` -> `{ssid: String?}`,
`discoverBulbHotspot` -> `{ssid: String, name: String}`, and `listBulbWifi` ->
`{networks: [{ssid: String}]}`. The discovery result is a verified Wi-Fi
hotspot, not a paired Tuya device. Native vendor models stay behind app-owned
values. The original `startPairing` AP contract remains.

## Acceptance criteria

- The app does not ask the user to manually type an SSID when a supported
  network name can be obtained or selected; manual entry remains available.
- No prefix-joined hotspot is displayed as a verified bulb. It is named as a
  device hotspot until the Tuya AP+ handshake succeeds, and only an activation
  callback plus home refresh can establish pairing success.
- Failure, timeout, permission denial, empty result and unsupported firmware
  all leave a usable AP fallback.
- No network password or real device identifier is logged, persisted, or added
  to tracked files. Thai and English labels are both present.
- Simulator and SDK-missing builds report unavailability honestly. Relevant
  Flutter checks and a physical-device iOS build pass.

## Implementation notes

- Current `ThingSmartDiscovery.startDiscoveryWithSsid:password:` requires
  credentials before scanning, so it cannot alone supply the requested first
  step. `ThingSmartAutoActivator` needs already-bound helper devices. Tuya's
  iOS Pairing UI BizBundle documents `searchTypeEZ` auto-discovery, but it is
  not currently installed and embeds vendor UI; the user explicitly prefers
  preserving the JAVIS design. The Wi-Fi-only box does not advertise BLE.
- Use Apple's `NEHotspotConfiguration(ssidPrefix:)` with the documented Tuya AP
  hotspot prefix and a join-once configuration. Require the Hotspot
  Configuration capability and verify the actual connected SSID before
  considering it found. The user confirms the iOS network-change prompt.
- Apple's public iOS Wi-Fi APIs can return the *current* SSID with Access Wi-Fi
  Information entitlement and location authorization, but cannot provide a
  general list of nearby routers. Request When In Use location solely to
  prefill the home network name and provide a manual fallback when declined.
- Tuya's new AP flow can query networks through the bulb after connecting to
  its hotspot, but requires TuyaOS firmware 3.6.1+, Hotspot capability, and
  `ThingSmartHotspotCredentialKit`; this bulb's firmware is not yet known. Pin
  the locally available `1.2.0` pod and treat unsupported/empty Wi-Fi lists as
  fallback conditions, never as evidence of a particular network. The SDK has
  AP+ resume overloads with and without security configuration; use the
  configuration when the optional request provides it.
- Official references:
  - https://developer.tuya.com/en/docs/app-development/deviceconfiguration?id=Ka8qf8lipvifj
  - https://developer.tuya.com/en/docs/app-development/iOS-network-host?id=Kaixw35qn5d1l
  - https://developer.apple.com/documentation/technotes/tn3111-ios-wifi-api-overview
  - https://developer.apple.com/documentation/NetworkExtension/NEHotspotNetwork/fetchCurrent%28completionHandler%3A%29
  - https://developer.apple.com/documentation/networkextension/nehotspotconfiguration

## Risks

- Smart Life may use a pairing component unavailable in the HomeKit pod or a
  firmware feature this Wi-Fi-only bulb does not expose to custom apps.
- Additional Tuya pods and iOS entitlements may affect clean builds or signing.
- Location permission may be declined; SSID auto-fill must remain optional.
- A network discovered by the bulb is not proof of 2.4 GHz compatibility until
  the SDK labels it compatible.

## Verification

- `dart format --output=none --set-exit-if-changed .` and `flutter analyze`
  passed; all 36 Flutter tests passed after the final review fixes.
- iOS profile device build without codesigning passed after the AP+ pod,
  entitlements, and native cancellation fixes. Both iOS plist files passed
  `plutil -lint`.
- Verify discovery and activation with the purchased bulb on a physical iPhone;
  a simulator cannot validate nearby hardware or Tuya activation. Confirm
  whether its firmware supports AP+ Wi-Fi-list queries or needs legacy AP.

## Current status

Custom Calm Ambient discovery-first and network-chooser UI, app-owned Flutter
bridge, iOS hotspot joining and AP+ network query, plus manual AP fallback are
implemented. A later physical-iPhone screenshot showed the purchased bulb
paired after a device Wi-Fi join prompt and home-network credential entry.
The exact AP+ versus manual AP path was not captured, so Wi-Fi-list support
for this firmware remains unconfirmed.
