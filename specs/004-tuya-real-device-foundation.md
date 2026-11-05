# Tuya real-device pairing and control foundation

Status: Physical pairing and on/off response confirmed
Last updated: 2026-10-18

## Context

JAVIS currently demonstrates pairing and lighting controls with
`MockLightingService`. The first hardware milestone is to pair and control one
Tuya/Smart Life-compatible RGB+CCT bulb from JAVIS on a physical iPhone. Real
activation requires an app-specific SmartLife iOS SDK package and credentials,
a Tuya app user and home, and the bulb's confirmed protocol and data-point
schema. The Tuya project and private package are now available locally; app
credentials are now stored only in the ignored local configuration; app-user
onboarding, the selected home, and verified device schema still need to be wired
into the native adapter.

## Goal

Prepare an honest, maintainable real-device path that can accept the provisioned
Tuya SDK without redesigning Flutter screens. The app must distinguish demo from
real mode, expose native readiness and pairing progress, cancel active work, and
surface actionable Thai/English failures. After the external prerequisites are
provided, complete one physical-iPhone pairing and confirm power control against
the real bulb.

## Non-goals

- Committing Tuya keys, security components, Wi-Fi passwords, account tokens, or
  household/device identifiers.
- Guessing DP identifiers, color encodings, temperature ranges, or a pairing
  mode before the bulb is identified.
- Implementing production authentication, multi-home management, persistence,
  scenes, voice control, Android support, or Go API Tuya commands.
- Falling back silently from real mode to demo data.
- Claiming simulator or stub success as physical-device activation.

## User flow and service contract

1. The build explicitly selects demo or Tuya mode. Demo remains the safe default
   for UI development; Tuya mode never mixes in demo devices.
2. Tuya mode initializes the native adapter and reports one of: ready,
   configuration missing, SDK unavailable, session required, unsupported
   simulator, permission denied, or transport failure.
3. Once the SDK, app user/home, and a confirmed pairing mode are available, the
   user resets the bulb, starts one pairing attempt, sees real progress, and may
   cancel it. Cancellation reaches the native provider and invalidates late
   callbacks.
4. Only provider-confirmed activation followed by a home/device refresh adds a
   bulb. Devices deduplicate by provider device identifier.
5. Commands are explicit desired values rather than stale whole-device snapshots.
   The UI preserves the last confirmed state until native device reports confirm
   the result.

Flutter owns app-facing immutable models and localized errors. A method channel
`com.javis.home/lighting` carries initialize, refresh, pair/cancel, and command
requests. An event channel `com.javis.home/lighting/events` carries session,
pairing, device and connectivity updates. Only app-owned codec-safe maps cross
the boundary; SDK objects, secrets, Wi-Fi credentials and raw exceptions do not.

## Acceptance criteria

### Foundation deliverable

- Demo and Tuya providers are selected explicitly and never mix their devices.
- Simulator, missing SDK configuration, unavailable session and permissions are
  represented honestly and do not report discovery success.
- Pairing exposes a unique operation ID, permits one active attempt, supports
  transport cancellation, and ignores terminal events from stale operations.
- App navigation/disposal cancels active pairing rather than merely closing UI.
- Provider-neutral capabilities allow unsupported controls to be hidden or
  disabled; no Tuya DP numbers or assumed bulb ranges leak into presentation.
- Native channel setup compiles without private Tuya artifacts and reports
  `sdkUnavailable` until the provisioned adapter is installed.
- Secrets/configuration locations are ignored by Git and documented with safe
  placeholders only.
- Thai and English cover readiness, configuration, pairing, cancellation and
  actionable error messages.
- Tests cover provider selection, unavailable native mode, cancellation/late
  result handling, deduplication and command failure behavior.

### Live-hardware completion

- An app-specific SmartLife iOS SDK package for `com.javis.home` is installed
  locally using its official security component and current privacy manifest.
- The exact bulb model, radio type, reset procedure, supported activation mode
  and DP schema are recorded here without household identifiers or secrets.
- A physical iPhone can activate the reset bulb into the selected Tuya home,
  cancel/retry safely, and avoid duplicates.
- Power on/off is confirmed by both the physical bulb and the provider's reported
  state. Brightness, white temperature and color are enabled only when supported
  and verified.
- Permission denial, wrong network credentials, timeout, offline/reconnect and
  app restart are exercised and recorded.

## Implementation notes

- Keep `LightingService extends ChangeNotifier`; add a small native-backed
  implementation rather than a state-management framework.
- Select the provider with a non-secret build definition such as
  `JAVIS_LIGHTING_PROVIDER=tuya`. Unknown values fail closed to an explanatory
  unavailable provider, not demo mode.
- Register one Swift bridge during Flutter's implicit-engine initialization.
  The initial checked-in bridge contains no Tuya imports and returns a stable
  SDK-unavailable error until the private integration is added.
- Subscribe to native events before initialization and use complete snapshots to
  recover missed events. Keep one pairing operation and invalidate it before
  stopping provider work.
- Send slider commands on commit (`onChangeEnd`) once real control is wired;
  serialize pending commands per device and reconcile against provider reports.
- Initial AP or BLE flow will be chosen only after bulb confirmation. Tuya
  currently recommends AP over EZ for Wi-Fi-only hardware; BLE requires a combo
  radio. Manual SSID/AP switching avoids adding unnecessary entitlements.
- Wi-Fi passwords remain in the active request only and are never persisted,
  logged, placed in analytics, or added to this specification.

## External prerequisites

- Remaining bulb brand/model or rear/bottom label, and whether it is currently
  bound to another account. Smart Life compatibility is now confirmed.
- A production-key rotation and provisioning process before distribution. The
  current development-edition AppKey and AppSecret are stored only in the
  ignored local configuration for this demo.
- A decided app-user/home onboarding flow. Smart Life app membership must not be
  assumed to transfer automatically to this App SDK project.
- Physical iPhone, bulb in reset/pairing mode, and compatible 2.4 GHz Wi-Fi for
  end-to-end verification.

## Purchased bulb evidence

Photos received on 2026-10-18 confirm only the claims printed on the visible
front/side packaging:

- The `WIFI` option is selected; `ZigBee` and `BLE` are not selected.
- The bulb advertises RGB color and adjustable white from 2700 K to 6500 K.
- The illustration shows an Edison screw base, but the visible packaging does
  not identify E26 versus E27.
- No brand, model number, product ID, or FCC ID is visible in the supplied
  packaging/manual photos. The initial packaging photos alone did not identify
  the ecosystem.

Additional manual photos received on 2026-10-18 confirm:

- The setup app is **Smart Life**, confirming Tuya/Smart Life ecosystem
  compatibility for this integration direction.
- The bulb supports 2.4 GHz Wi-Fi only; 5 GHz is explicitly unsupported.
- The documented reset/pairing action is to turn the bulb off/on three times
  until it blinks.
- The manual shows the standard Smart Life Wi-Fi light flow and advertises Alexa
  and Google Home linking.

The hardware path is therefore Tuya/Smart Life Wi-Fi activation, not BLE or
Zigbee. The screenshots resemble the standard fast-blink Wi-Fi flow, but the
actual SDK activation mode and DP schema will be confirmed on-device rather
than inferred from the generic manual. Brand/model and whether the bulb is
already bound remain unknown.

## Risks

- The purchased bulb might be Wi-Fi-only, Wi-Fi/BLE combo, Matter, Zigbee, or a
  product not authorized for this SDK project; the required integration differs.
- Tuya's app-specific security package cannot be replaced by public pods or cloud
  Access ID/Secret values.
- Publishing a command can succeed before the bulb reports the resulting state;
  treating callback acceptance as confirmation would create false UI state.
- AP switching/backgrounding and delayed provider callbacks can create duplicate
  or stale completion unless operations are identified and reconciled.
- Tuya plan/licensing limits must be confirmed before commercial distribution.

## Verification

Completed on 2026-10-18:

- `dart format --output=none --set-exit-if-changed .`: passed, 16 files
  unchanged.
- `flutter analyze`: passed with no issues.
- `flutter test`: all 24 tests passed. Coverage includes explicit provider
  selection, missing native provider, command validation/serialization,
  cancellation, stale callbacks, provider deduplication, native cleanup on
  failed pairing and stale snapshots across session/readiness changes.
- `flutter build ios --simulator --debug` and Tuya-mode `flutter run` on an
  iPhone 15 Pro Simulator passed. The Swift bridge reported
  `unsupportedSimulator`, the app showed zero real devices and no demo fallback,
  and the Thai/English guidance rendered without clipping.
- Visual captures: `build/iphone-tuya-unavailable.png` and
  `build/iphone-tuya-unavailable-th.png`.
- A correctness/security review found two medium-priority async cleanup issues.
  Both were fixed, regression-tested and confirmed resolved in a focused
  re-review. No credential exposure or fabricated native success was found.
- Physical iPhone `Mind Tatchai` was initially blocked by Developer Mode.
  Developer Mode was subsequently enabled and the current SDK-unavailable build
  installed and launched successfully on the connected iPhone.
- A Smart Life App SDK project named `JAVIS` was created in Tuya Developer
  Platform for iOS bundle ID `com.javis.home`, region outside mainland China,
  using development edition v7.8.0 and Tuya's temporary development domain.
- The generated `iOS_SDK.zip` was downloaded and its private
  `ThingSmartCryption` package was extracted under ignored path
  `ios/LocalTuya/ios_core_sdk/`. The package includes iOS device and simulator
  slices plus the matching podspec. No key or secret was copied into tracked
  files.
- CocoaPods installed `ThingSmartHomeKit 7.8.0.6`, the matching local
  `ThingSmartCryption` component, and required transitive pods. Flutter's custom
  Debug/Release/Profile configurations now include the corresponding Pods
  xcconfig files. `flutter build ios --simulator --debug` passed with the SDK
  linked; Tuya's x86_64-only simulator dependencies are excluded from arm64 as
  directed by the generated Podfile.
- `flutter build ios --debug --no-codesign` passed for the physical-device arm64
  target, confirming that the downloaded private framework links for iPhone.
- The development AppKey and AppSecret were copied directly from Tuya Developer
  Platform into ignored `ios/Runner/TuyaConfig.local.plist`. The plist validates,
  both values are non-empty, and neither value was printed or added to tracked
  files.
The native AppKey/AppSecret load, Keychain-backed demo app user/home, and AP
pairing adapter are implemented as specified in `006-tuya-iphone-pairing.md`.
At the time of this foundation verification, the real bulb had not yet been
paired. Later physical pairing and on/off results are recorded in
`010-real-bulb-power-control.md`.

## Current status

The provider-neutral Flutter service, Swift bridge, explicit build-mode
selection, bilingual setup experience, private SDK integration, local demo
credentials, app user/home, AP activation and regression coverage are complete.
The installed debug build was not directly launchable from the iPhone Home
Screen because Flutter requires developer tooling for debug launch on iOS 14+;
the user will use `flutter run --profile` for independent testing. Hardware/manual evidence
confirms Smart Life Wi-Fi RGB+CCT (2700–6500 K), 2.4 GHz-only networking and a
three-cycle blink reset procedure. A later screenshot from the user's physical
iPhone shows `Smart-Bulb-E27-wifi` in JAVIS after the Tuya activation callback
and home refresh; the exact AP/AP+ branch was not recorded. The power control
path is implemented under `010-real-bulb-power-control.md`. The user has since
confirmed that the bulb returned to JAVIS after app relaunch and responds to
both on and off on the physical iPhone. Brightness, temperature, and RGB
remain unverified and disabled.
