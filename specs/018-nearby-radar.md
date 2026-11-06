# Nearby radar: one search for every device

Status: Implemented, hardware checks open  
Updated: 2026-11-06

Replaces the device-type screen (screen 14 of spec 012) and the found-device sheet
of `013-ble-nearby-pairing.md`. The Bluetooth bridge, the Wi-Fi fallback, and the
pairing itself stay as they are.

## Context

Add device opens with a choice between a light bulb and a door lock, and only then
starts searching. Smart Life does not ask: it opens "Searching for nearby devices…"
and lists what it finds with a name and an icon. The owner wants the same, as a
radar rather than a list with a spinner.

The native scan already has no category filter: it accepts any inactive Wi-Fi + BLE
combo device. So the choice protects nothing. It also names the device by counting
("New light 1"), because nothing is read from the product before activation.

## Goal

Tap + and the search starts by itself on a radar. Everything nearby in pairing mode
blooms onto it with its name and icon, and one tap starts adding it.

## Non-goals

- Lock controls, lock schema, or a lock screen. A lock can be found and paired here,
  but it stays a device with no controls until the lock work has its own spec.
- Changing the Wi-Fi password step. A Wi-Fi + BLE device still needs the network.
- Finding Wi-Fi-only devices on the radar. They stay on "Set up with Wi-Fi".
- Showing distance or direction. Placement on the radar is decoration, and nothing
  on the screen claims that it means where the device is.

## User flow

1. Dashboard or zone → Add device. The radar screen opens and the scan starts.
2. Bluetooth off or not allowed → the radar goes still and the existing message
   appears. The scan resumes by itself when Bluetooth is available.
3. A device found → it blooms onto the radar with a confirm haptic, and a row appears
   below with its icon, name and Add.
4. Add, on the row or on the radar → the existing Wi-Fi step, then the existing
   progress and naming steps.
5. "Can't find it? Set up with Wi-Fi" stays available while scanning.
6. In the demo, sample devices appear on the same radar. Add goes straight to the
   existing demo pairing, with no Wi-Fi step.

## Bridge contract

Additive. `nearby` events carry optional fields:

```text
{type: nearby, devices: [{id: String, name?: String, iconUrl?: String}]}
```

`id` stays the app-owned opaque id. The BLE UUID and product ID stay native. A device
with no name shows a numbered "New device"; one with no icon shows a generic icon.

## Acceptance criteria

- Add device opens the radar directly, from the dashboard and from a zone. The type
  screen and its strings are gone.
- The scan starts without a tap. Leaving the screen stops it.
- Found devices are listed by name and icon when the product info is available, and
  the screen still works when it is not.
- The radar never moves when a device arrives, and a list row reserves no surprise
  jump above it. The radar and the list keep their places.
- Reduce Motion shows still rings, with no sweep or pulse.
- VoiceOver reaches every found device through the list, and the status is a live
  region. The radar itself is decorative.
- Light and dark, Thai and English, and 2× text all fit.
- Failure, cancel, retry and the Wi-Fi fallback keep working.

## Implementation notes

- `lib/features/pairing/nearby_radar.dart` holds the radar. One repeating controller
  drives a `CustomPainter` inside a `RepaintBoundary`, using `CalmPalette` tokens.
  Blips are widgets on top, so they use `Pressable`.
- `NearbyDevice` gains optional `name` and `iconUrl`. Only `https` icons are loaded.
- `TuyaLightingAdapter` calls `queryDeviceInfoWithUUID:productId:` once per device
  and re-emits `nearby` when the answer arrives. A failed query is not an error: the
  device stays usable with the generic label.
- `MockLightingService` now scans, so the demo and the Simulator show the same screen.
- Reference: https://developer.tuya.com/en/docs/app-development/ble?id=Ka5vcxzbglphd

## Risks

- Tuya's docs say the query returns the device name and do not list the keys. A real
  bulb returned both `name` and `icon` on 2026-11-06. Other products are untested, and
  a missing key falls back to the generic label and icon.
- A blinking bulb can be missing from the scan. On 2026-11-06 the iPhone received no
  advertisement from one until it was powered off for 10 seconds and on again. Why it
  was silent before that is not known.
- A paired lock lands in the home through the light model, so it shows as a device
  with no controls and is registered with kind `light` until the lock work is done.
- Copy on later steps of the Wi-Fi fallback still says "bulb", which is accurate for
  those paths today.

## Verification

Run on 2026-11-06.

- `dart format --output=none --set-exit-if-changed .`, `flutter analyze` and
  `flutter test` pass, with tests for opening directly on the radar, Thai, adding
  from the radar, Reduce Motion, 2× text, names, `https`-only icons, and duplicates.
- Simulator (iPhone 15 Pro, iOS 17), demo provider: dark in English and light in
  Thai, checked by eye with two sample devices.
- `flutter build ios --profile` passes with the real Tuya provider, and that build is
  on the owner's iPhone.

Run on 2026-11-06 on the owner's iPhone, as a profile build with the Tuya provider and
the local API: the radar found a real bulb and paired it. The API recorded the claim
and the rename, and Tuya then reported the bulb online over both cloud and LAN.

Not verified yet: how the real name and product icon look on the radar, the 60 fps
target on hardware (the debug Simulator is too slow to judge), and the Bluetooth off
or denied states on the device.

## Current status

The radar replaces the type screen and the found-device sheet in the demo and the
Tuya provider. Hardware checks above are open.
