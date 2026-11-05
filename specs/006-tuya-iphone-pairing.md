# Tuya iPhone pairing demo

Status: Implemented; physical pairing and on/off confirmed
Last updated: 2026-10-18

This spec records the legacy AP fallback. The later discovery-first hotspot
joining and AP+ flow are specified in `008-discovery-first-pairing.md`; they
supersede the manual-first entry journey below when supported by the bulb.

## Context

The app-specific Tuya 7.8 iOS SDK, private security component, and ignored local
demo AppKey/AppSecret are provisioned. The native adapter now initializes the
SDK and implements AP pairing on iPhone. The purchased Wi-Fi-only Smart Life
bulb has not yet been tested with this flow. Its manual documents 2.4 GHz Wi-Fi
and a three-cycle power reset until blinking.

## Goal

On a physical iPhone, initialize the SDK, establish one reusable demo app user
and Tuya home, then attempt legacy AP (slow-blink) Wi-Fi activation from JAVIS with an
entered 2.4 GHz SSID/password. Show honest progress, errors and cancellation.
Only report success after the Tuya activation callback and a home refresh.

## Non-goals

- Production identity, account recovery, multi-home selection or cloud API work.
- Persisting a Wi-Fi password, exposing Tuya credentials in Dart, or committing
  private packages and configuration.
- Claiming power/color support until the paired device DP schema is checked.
- Automating iOS Wi-Fi access point switching or adding BLE support.

## User flow and bridge contract

1. In Tuya mode, `initialize` loads `TuyaConfig.local.plist` from the local iOS
   build, starts the SDK, and reports `sessionRequired` if no app user/home is
   ready. Simulator remains unsupported. A clean checkout without local Tuya
   packages/config reports the corresponding unavailable state.
2. The user taps a demo home setup action. `prepareHome` creates or resumes one
   UID/password app user stored in iOS Keychain, selects or creates a Tuya home,
   and returns a full readiness/device snapshot. The demo country code is 66
   (Thailand). No account credentials cross the Flutter channel.
3. The user enters the 2.4 GHz router SSID/password and resets the bulb into
   slow-blink AP mode. `preparePairing` obtains a short-lived token while the
   iPhone still has internet. The user switches iPhone Wi-Fi to the bulb's
   hotspot in Settings and returns to JAVIS. `startPairing` accepts
   `operationId`, `ssid`, `password`, and `mode: ap`, and uses the cached token.
   Wi-Fi credentials stay in memory only for the active activation request.
4. Native pairing emits operation-tagged `searching`, `activating`, `success`
   (with provider device ID), or `failed` events. Cancellation stops the Tuya
   activator; late callbacks cannot finish the old attempt. Flutter refreshes
   the home after success and only adds the provider-confirmed device.
5. Device controls remain capability-gated. Unknown DP schema exposes no
   unverified controls and `sendCommand` returns `unsupportedCommand`.

## Acceptance criteria

- SDK initializes with ignored local configuration on iPhone, and a missing
  package/configuration remains an honest error.
- Demo app identity survives app relaunch via Keychain and does not create a new
  cloud user on every launch. Existing home is reused.
- No password or AppSecret is printed, logged, persisted in Dart, or added to
  tracked files. Native errors are sanitized before crossing the channel.
- Pairing button requires non-empty Wi-Fi fields, a fresh pairing token and a
  ready session. The user can cancel/retry; stale operation callbacks are ignored.
- English/Thai copy explains slow blinking, bulb hotspot switching, 2.4 GHz Wi-Fi, and actionable
  failures without promising physical success prematurely.
- Physical iPhone build succeeds. Actual bulb activation and DP mapping are
  verified separately on hardware and recorded below.

## Implementation notes

- Keep the Tuya SDK behind `LightingNativeAdapter` in `ios/Runner` and compile
  it conditionally when the local private pod is installed. Bridge maps carry
  app-owned values only.
- Build copies the ignored local plist into the app bundle for demo only. It is
  never included in source control. Tuya App SDK requires its key/secret at
  runtime; a distributed app needs a separate production security review.
- Use Tuya 7.8 headers for actual API signatures. Tuya documents that EZ on
  modern iOS requires an Apple-approved multicast entitlement, which this app
  does not have. The initial flow uses legacy AP, which Tuya recommends for
  compatibility. Confirm that the bulb can enter slow-blink AP mode on device.
- The token expires after 10 minutes; cache it for at most 8 minutes and
  require refresh before a later attempt. Never send the token to Dart.
- Keep Flutter provider boundaries and existing pairing operation IDs.

## Risks

- Bulb might already be bound to another account or lack an AP mode despite its
  generic manual. The printed reset instruction only confirms blinking, not
  the exact slow-blink transition.
- iOS local network access, router isolation, 5 GHz-only SSID, wrong password,
  or Tuya development quota may block activation.
- App uninstall can remove the cloud-session link; Keychain persistence across
  reinstall is platform-dependent and this flow has no account recovery.

## Verification

- Swift/iOS app builds passed for arm64 physical device in debug mode, both
  without signing and with automatic development signing. Profile mode built
  without signing after the pairing UI redesign. The signed debug app installed
  and launched via developer tooling on the connected iPhone.
- The local plist was verified as present and syntactically valid in the built
  app without printing its values.
- Flutter formatting and analysis passed; all 28 Flutter tests passed after the
  AP flow and UI work. Tests include token-preparation sequence, Wi-Fi argument
  forwarding, cancellation, retry/password clearing and stale callbacks.
- Security-focused review found no remaining actionable secret/cancellation
  issues. Unknown device power is shown as unavailable instead of falsely Off.
- Actual Tuya cloud login/home creation, bulb hotspot availability, activation,
  and physical power response were unverified at that time. The first installed debug app
  was opened from the iPhone Home Screen and displayed Flutter's iOS 14+ debug
  launch notice; launch it through `flutter run`, or use a signed profile build.

## Current status

Implementation complete for the AP pairing path, including Keychain demo user,
home reuse, short-lived token preparation, network form, manual hotspot switch,
native activation, cancellation and provider-confirmed device refresh. The
user's physical-iPhone screenshot later showed the purchased bulb paired in
JAVIS after joining a device Wi-Fi hotspot; the exact AP/AP+ branch was not
recorded. On/off control is now addressed separately in
`010-real-bulb-power-control.md`; the user subsequently confirmed on/off
operation of the real bulb on a physical iPhone.
