# Bluetooth nearby-device pairing

Status: Implemented on iOS; physical BLE pairing observed  
Last updated: 2026-11-06

The entry screen and the found-device sheet below were replaced by
`018-nearby-radar.md`. The bridge and activation described here still apply.

Adds a Bluetooth-first path in front of the Wi-Fi paths in
`008-discovery-first-pairing.md` (AP/AP+) and `009-fast-blink-ez-pairing.md`
(EZ). Those paths stay, unchanged, as "Set up with Wi-Fi instead".

## Context

The user tested Smart Life with the purchased bulb on 2026-11-01. With
Bluetooth switched off in iPhone Settings, Smart Life found nothing and asked
the user to turn Bluetooth on. As soon as Bluetooth was on, the blinking bulb
appeared without the iPhone joining any bulb Wi-Fi. The bulb therefore
advertises over Bluetooth LE in pairing mode, so it is a Wi-Fi + BLE combo
(dual-mode) device.

JAVIS previously made the user join a `SmartLife…` hotspot (AP). The user
wants the Smart Life experience. The user first asked to delete the Wi-Fi
paths, then reversed that: some bulb brands are Wi-Fi only and cannot be
found over Bluetooth, so the Wi-Fi paths remain as the fallback.

The installed `ThingSmartHomeKit ~> 7.8.0` already brings `ThingSmartBLEKit`
and `ThingSmartBLECoreKit` (see `ios/Podfile.lock`). No new pod is needed.

## Goal

Tap + → Light bulb, and a blinking bulb nearby appears by itself. Choose it,
confirm the 2.4 GHz home Wi-Fi password, and the light joins the home. If
Bluetooth is off or not allowed, say so clearly and resume scanning by itself
when Bluetooth becomes available. A bulb that never appears can still be
added with the existing Wi-Fi setup.

## Non-goals

- Android. The bridge contract below is written so an Android adapter can
  implement the same methods and events later (Tuya Android:
  `getBleOperator().startLeScan`, `newMultiModeActivator().startActivator`).
  The Android app is not yet registered in the Tuya IoT console.
- Changing or removing AP, AP+ or EZ behavior.
- Bluetooth-only (no Wi-Fi) activation, single-mode BLE devices, mesh, Zigbee.
- Showing the vendor product name or icon before activation (see Risks).
- Remembering the Wi-Fi password between attempts.
- The demo provider flow, which stays as it is.

## User flow

1. The add-light screen opens in "nearby" mode and immediately starts a
   Bluetooth scan.
2. Bluetooth off → a warm note asking to turn Bluetooth on. Bluetooth not
   allowed → a note to allow Bluetooth for JAVIS in iPhone Settings. The
   screen keeps listening; once Bluetooth is on, scanning resumes by itself.
3. While scanning, show "Looking for lights nearby…" and a reminder to put the
   bulb in pairing mode (blinking).
4. When the first nearby device is found, a sheet slides up listing what was
   found. Found devices also stay listed on the page.
5. Choosing a device shows the Wi-Fi step: the current home SSID is prefilled
   when iOS allows it, otherwise typed. The user enters the password and taps
   Connect a light. The iPhone stays on home Wi-Fi.
6. Progress uses the existing checklist. Success requires the Tuya activation
   callback plus a home refresh that contains the device.
7. Failure or cancel → Try again restarts the scan with the password cleared.
   "Add another light" opens a fresh scan for the next bulb.
8. "Set up with Wi-Fi instead" stops the scan and shows the existing EZ/AP
   chooser. "Find nearby with Bluetooth" returns to the scan.

## Bridge contract (Flutter ↔ native)

New methods on `com.javis.home/lighting`:

| Method | Arguments | Reply |
|---|---|---|
| `startDeviceScan` | – | `{bluetooth: on\|off\|unauthorized\|unsupported}` |
| `stopDeviceScan` | – | `{stopped: true}` |

`startPairing` accepts `mode: ble` in addition to `ap` and `ez`. With
`mode: ble` it also requires `deviceId`; it does not need `preparePairing`.
All other existing methods are unchanged.

New events on `com.javis.home/lighting/events`:

- `{type: bluetooth, state: on|off|unauthorized|unsupported}`
- `{type: nearby, devices: [{id: String}]}` — the full current list.

`deviceId` is an app-owned opaque id (`nearby-1`, `nearby-2`, …) issued by the
native adapter for one scan. The BLE UUID and product ID stay native. New
error codes: `deviceNotReady` (the device is not in pairing mode) and
`bluetoothOff`.

## Acceptance criteria

- Opening the add-light screen in real mode starts a scan without an extra
  tap; leaving the screen or switching to Wi-Fi setup stops it.
- Bluetooth off and Bluetooth not allowed each have their own bilingual
  message; turning Bluetooth on resumes scanning without leaving the screen.
- Only Tuya dual-mode Wi-Fi types (`ThingSmartBLETypeBLEWifi`,
  `…BLEWifiSecurity`, `…BLEWifiPlugPlay`, `…BLEWifiPriorBLE`) that are not yet
  active are listed. Duplicates collapse to one entry.
- The first discovery opens a sheet once per scan; choosing a device leads to
  the Wi-Fi step, which never asks the user to join another network.
- Cancel, leaving the screen, or a stale event can never add a light. Success
  only after the activation callback and a home refresh containing it.
- The Wi-Fi password is never persisted, logged or sent back to Flutter.
- The EZ/AP/AP+ flows and their tests keep working behind the Wi-Fi option.
- Thai and English for every new message. Format, analyze and tests pass,
  and an unsigned iOS device build passes.

## Implementation notes

- Scan: `ThingSmartBLEManager.sharedInstance().delegate = adapter`, then
  `startListening(true)`; results arrive in
  `didDiscoveryDevice(withDeviceInfo:)` as `ThingBLEAdvModel` (`uuid`,
  `productId`, `bleType`, `isActive`). Stop with `stopListening(true)`.
  Bluetooth changes arrive in `bluetoothDidUpdateState(_:)`; the manager also
  exposes `isPoweredOn`. "Off" versus "not allowed" is told apart with
  CoreBluetooth's `CBManager.authorization`.
- Pair: `ThingSmartBLEWifiActivator.sharedInstance()`, `bleWifiDelegate =
  adapter`, `startConfigBLEWifiDevice(withUUID:homeId:productId:ssid:password:
  timeout: 100, …)`. Per Tuya's docs its `success` block only means the pairing
  data was sent (reported as `activating`); the result arrives in
  `bleWifiActivator(_:didReceiveBLEWifiConfigDevice:error:)`.
  `bleWifiActivator(_:notConfigStateWithError:)` maps to `deviceNotReady`.
  Cancel clears the delegate first, then calls `stopDiscover()`.
- Flutter keeps operation ids, the session generation and stale-event guards.
  `LightingService` gains `bluetooth`, `nearbyDevices`, `startDeviceScan` and
  `stopDeviceScan`; `WifiPairingConfiguration` gains `mode: ble` and the chosen
  `deviceId`. Nearby UI lives in `lib/features/pairing/nearby_pairing.dart`.
- `Info.plist` adds `NSBluetoothAlwaysUsageDescription`. No entitlement or pod
  changes.
- References:
  - https://developer.tuya.com/en/docs/app-development/ble?id=Ka5vcxzbglphd
  - https://developer.tuya.com/en/docs/app-development/android-bluetooth-ble?id=Karv7r2ju4c21

## Risks

- Unverified: the exact `bleType` this bulb reports. If it is not one of the
  four Wi-Fi types it will not be listed; the Wi-Fi option still works.
- Unverified: the product name/icon. Tuya's
  `queryDeviceInfoWithUUID:productKey:` returns an undocumented dictionary, so
  JAVIS shows a generic numbered "New light" label until the keys are checked.
- Unverified: whether `stopDiscover()` aborts a pairing already in progress;
  the docs only say it stops polling. JAVIS invalidates the attempt locally,
  so a late result cannot add a light.
- The Tuya BLE manager and BLE-Wi-Fi activator are singletons; late callbacks
  are filtered by operation id and device UUID.
- The router must still be 2.4 GHz.

## Verification

- 2026-11-01: `dart format --output=none --set-exit-if-changed .` and
  `flutter analyze` passed; all 53 Flutter tests passed, including new tests
  for scan-on-open, the found-light sheet, `mode: ble` with `deviceId`,
  Bluetooth off/denied/on, scan stop on Wi-Fi setup and on leaving, ignored
  late `nearby` events, and the missing-device guard. Existing EZ/AP tests now
  enter through "Set up with Wi-Fi".
- `flutter build ios --profile --no-codesign
  --dart-define=JAVIS_LIGHTING_PROVIDER=tuya` passed against the installed
  Tuya pods; `Info.plist` passed `plutil -lint`.
- 2026-11-01, physical iPhone (iOS 26.6.2, `flutter run --profile`, Tuya
  provider): the user reported that the purchased blinking bulb popped up in
  the found-light sheet and paired successfully. Its `bleType` is therefore
  one of the four listed Wi-Fi combo types (exact value not logged).
- The user then reported that on/off control of the BLE-paired bulb works.
- Not yet reported: the Bluetooth off/on and denied cases on the device, and
  pairing a second bulb with "Add another light".

## Current status

iOS Bluetooth scan, found-light sheet, BLE + Wi-Fi activation and the
Bluetooth state messages are implemented, with EZ/AP kept behind "Can't find
it? Set up with Wi-Fi". The purchased bulb was found and paired over
Bluetooth on the user's iPhone, and on/off control works. Android not started.
