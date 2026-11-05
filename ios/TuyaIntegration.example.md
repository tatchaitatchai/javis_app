# Local SmartLife iOS SDK setup example

This file documents the local-only SDK integration. The checked-in adapter uses
the Tuya SDK only when the app-specific package is installed. Private binaries
and credentials remain ignored. A successful build is not proof of bulb pairing.

## Required external package

The development-edition v7.8.0 package for the Tuya Developer Platform project
created specifically for `com.javis.home` was downloaded on 2026-10-18. Its
archive and extracted security component stay in the ignored `ios/LocalTuya/`
directory. For a fresh workstation, obtain these items again from that project:

- SmartLife iOS App SDK **v7.8.0** package selected for that project.
- Its generated `ios_core_sdk.tar.gz`, including the matching app-specific
  `ThingSmartCryption` security component and `Build/` contents.
- The SDK's current privacy manifest and integration instructions.
- The app's demo setup creates or resumes one UID app user and a demo home.

The official CocoaPods integration uses Tuya's private specs source and the
app-local `ThingSmartCryption` podspec. The generated development package and
current `ios/Podfile` install `ThingSmartHomeKit ~> 7.8.0`; this is the minimum
SDK for the custom JAVIS UI. Add `ThingSmartBusinessExtensionKit` only when a
specific required capability justifies rebuilding the SDK selection. Add its
BLE Extra component only if the identified bulb actually supports BLE-combo
activation. Do not add the native Activator UI BizBundle unless the custom
pairing flow is intentionally replaced.

The Podfile detects the ignored private podspec before adding Tuya dependencies.
This keeps a fresh checkout buildable in demo mode without pretending that the
real provider exists; placing the official package at the documented path and
running `pod install` enables the native dependency locally.

The app-specific security component is not interchangeable with cloud API Access
ID/Secret credentials or a package generated for another bundle identifier. Do
not copy a public sample's keys or security files.

Keep downloaded packages and the extracted app-specific security component
under `ios/LocalTuya/`, optional native-only security material under
`ios/Runner/TuyaSecurity/`, and any local configuration at
`ios/Runner/TuyaConfig.local.plist`. All three locations are ignored by Git.
Do not place secrets, Wi-Fi passwords, account tokens, household identifiers, or
device identifiers in source, build settings, logs, screenshots, or specs.
Use `ios/Runner/TuyaConfig.example.plist` as the field-name reference. The
ignored `TuyaConfig.local.plist` is populated only on the developer workstation;
never send either value through chat or copy that file into tracked sources.

## Adapter boundary

`Runner/AppDelegate.swift` registers:

- Method channel: `com.javis.home/lighting`
- Event channel: `com.javis.home/lighting/events`

`TuyaLightingAdapter.swift` is compiled conditionally with the SDK on a physical
iPhone. Simulator reports `unsupportedSimulator`; missing packages report
`sdkUnavailable`; missing local configuration reports `configurationMissing`.
The Xcode build copies the ignored local plist to `Runner.app/TuyaConfig.plist`
without printing its contents. The SDK requires these app credentials at
runtime, so a distributed build needs a production security review.

`prepareHome` authenticates a persistent, randomly generated UID/password in
Thailand (country code 66), lists homes, and reuses the saved home or creates
`JAVIS Demo Home` if there are no homes. The UID, password and selected home ID
are stored together in a nonsynchronizing, device-only Keychain item accessible
while unlocked. No account or Wi-Fi password crosses back to Flutter. This
installation-specific demo has no account recovery or multi-home UI.

`preparePairing` obtains a token while internet is available; the token stays
native and expires locally after eight minutes. `startPairing` accepts
`operationId`, router `ssid`, router `password`, and `mode: ap` or `mode: ez`.
Fast-blink EZ keeps the iPhone on the home Wi-Fi. Slow-blink AP can use the
custom JAVIS hotspot discovery/AP+ network chooser or the manual AP fallback.
Each attempt uses its own activator; cancel/terminal callbacks invalidate it
before stopping it, so stale SDK callbacks cannot complete a new attempt.
Tokens are consumed per attempt; retry starts with `preparePairing`. Only
provider activation confirmation followed by a refreshed home can make
Flutter report success. SDK errors are replaced with app-owned messages/codes.

Local network and location usage have purpose strings. Location access is used
only to prefill the current home SSID; it is optional and does not reveal the
Wi-Fi password. AP hotspot joining uses a system prompt. EZ requires Apple's
restricted multicast entitlement on a physical iPhone. The example
`TuyaConfig.example.plist` has `EnableEZ=false`; keep it false/absent in the
ignored local config until Apple approves multicast for `com.javis.home`, the
app is signed with an updated profile, and both the profile and signed app
entitlements are checked. The in-app flag is an explicit developer opt-in,
not a runtime signature verification; iOS still enforces the entitlement.
Do not add the multicast key to `Runner.entitlements` or set `EnableEZ=true`
before approval. See [Apple's entitlement guidance](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.networking.multicast)
and [diagnostic steps](https://developer.apple.com/documentation/bundleresources/diagnosing-issues-with-entitlements).

Bluetooth is used for nearby Wi-Fi + BLE pairing (spec 013):
`NSBluetoothAlwaysUsageDescription` is in `Info.plist`, `startDeviceScan` /
`stopDeviceScan` drive the Tuya BLE scan, and `startPairing` accepts
`mode: ble` with the scan's `deviceId`; no token preparation is needed for it.
The current user has not confirmed access to a paid
Apple Developer Program team, so physical EZ activation remains blocked by
external approval/signing even though the app flow is implemented.
The real bulb DP schema is not mapped yet: all device control capabilities
remain false and commands return `unsupportedCommand`. Power state is unknown;
presentation must gate its power labels/counts on the power capability rather
than interpreting the bridge's default boolean as a confirmed off state.

## Physical-device check

Enable Developer Mode on the iPhone, configure Automatic Signing for your Apple
development team, connect the phone, then run:

```sh
flutter devices
flutter run -d <physical-iphone-device-id> \
  --dart-define=JAVIS_LIGHTING_PROVIDER=tuya
```

With package and config present, the first physical-device result is
`sessionRequired`. Tap demo setup while connected to the internet. The add
screen defaults to fast-blink EZ for the purchased bulb; it explains when EZ
has not been enabled for this signed app. After approval and verified signing,
select the 2.4 GHz home Wi-Fi, enter its password, and leave the iPhone on that
network during EZ activation. For another bulb with slow-blink AP mode, choose
the AP path; the system may offer to join the bulb hotspot. Allow iOS Local
Network access when prompted. If activation succeeds but home refresh fails,
reconnect to the home Wi-Fi and refresh; do not assume the bulb needs another
reset. Actual hardware activation still needs observation.
