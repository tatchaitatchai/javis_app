# Real bulb power control

Status: Implemented; physical on/off confirmed
Last updated: 2026-10-18

## Context

The purchased Wi-Fi Smart Life bulb has now paired on a physical iPhone and
appeared in JAVIS as `Smart-Bulb-E27-wifi`. The existing native adapter still
reports every real-device capability as unsupported and rejects every command.
The bulb's numeric Tuya DP identifier is not yet known.

## Goal

Enable safe on/off control for a paired Tuya light using its runtime schema and
reported state, while preserving the Calm Ambient device-detail experience.

## Non-goals

- Guessing a numeric DP identifier or enabling brightness, temperature, or RGB.
- Resetting, re-pairing, or changing the user's existing bulb/home.
- Treating a publish acknowledgment as proof that the bulb changed state.

## User flow and bridge contract

1. A real-device refresh reads each home's device schema and current DP state.
   On app relaunch, an existing Keychain-backed demo identity automatically
   restores its Tuya home; a first-time install still requires explicit setup.
2. Power is available only if exactly one writable Boolean light-switch schema
   entry with a recognized power code is present and has a Boolean reported DP.
3. The detail and home controls enable only when that device is online and has
   the power capability. Tapping sends an explicit desired Boolean value through
   the existing `sendCommand` bridge.
4. Native publishing completes asynchronously. A publish failure surfaces as an
   error; reported DP/online changes update the device snapshot and Flutter UI.
5. Unknown schema, missing state, offline devices and unsupported command shapes
   remain disabled/rejected.

## Acceptance criteria

- No hard-coded numeric DP ID, credential, password, home or device identifier.
- Only on/off is enabled for a uniquely verified writable Boolean light-switch
  DP and its latest reported Boolean state.
- Native validates the requested command and device again before publishing.
- Publish failure is returned to Flutter; UI never optimistically flips power.
- DP/online updates refresh the visible state without requiring navigation.
- Relaunching a previously paired installation loads its existing home and bulb
  without repeating pairing or creating a new identity on first launch.
- Demo behavior and SDK-unavailable path remain unchanged.

## Implementation notes

- Use `ThingSmartDeviceModel.schemaArray` / `dps` and
  `ThingSmartDevice.publishDps` from the installed Tuya iOS SDK. Retain device
  objects while observing delegate updates.
- Recognize only a documented light power code (initially `switch_led`), not
  arbitrary Boolean or wall-switch DPs. A real bulb without this code remains
  safely unsupported until its schema can be inspected and added deliberately.
- Tuya identifies `switch_led` as the Boolean on/off DP for light products:
  https://developer.tuya.com/en/docs/iot/dj?id=K9i5ql3v98hn3 . The numeric
  DP ID is still discovered from each device's own runtime schema.
- Keep the provider-neutral channel contract; no SDK objects cross into Dart.

## Risks

- The paired bulb may use a different power code, expose stale DP data, or be
  temporarily offline. In those cases control stays disabled.
- Publish acknowledgment may precede the physical state update; listen for
  provider reports and avoid presenting acceptance as confirmed state.
- Physical operation needs a signed app on the user's iPhone and cannot be
  proven by simulator or an unsigned build.
- Keychain and Tuya cloud session restoration can fail if the phone is offline;
  the explicit prepare-home retry remains available.

## Verification

- `dart format --output=none --set-exit-if-changed .`: passed; 16 files,
  0 changes.
- `flutter analyze`: passed with no issues.
- `flutter test`: all 42 tests passed. The command test confirms that publish
  acceptance leaves state unchanged until a provider device event. New tests
  cover automatic restore of an existing home and no account creation on a
  fresh installation.
- `flutter build ios --debug --no-codesign`: passed for the physical iPhone
  target. A signed `flutter run --profile` built, installed and launched the
  updated real-provider app on the connected physical iPhone. After adding
  automatic home restoration, all 42 tests and analysis passed, an unsigned
  iOS profile build passed, and the final signed profile build was installed
  and launched on the iPhone with a live Dart VM service. An earlier Flutter
  tooling connection dropped, but `devicectl` still listed `Runner` as running
  on the phone; this is not evidence of an app crash.
- The user confirmed on 2026-10-18 that the paired bulb returned to the JAVIS
  device list on the physical iPhone and that its on/off control operates the
  actual light. This confirms the runtime power capability and command path
  for this bulb; it does not verify brightness, color, or temperature.

## Current status

The physical pairing screenshot confirms the bulb is in the JAVIS Tuya home.
Native code now detects the supported switch from the runtime schema, publishes
only explicit Boolean on/off commands, and forwards SDK status reports to
Flutter without optimistic state changes. A previously paired Keychain-backed
installation now restores its Tuya home at launch. The updated app is on the
user's iPhone. The user verified that the bulb is visible and physically
responds to on/off from JAVIS. Other light capabilities remain disabled until
their own device schema and behavior are verified.
