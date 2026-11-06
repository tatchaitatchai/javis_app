# 015 — Connect the app to the JAVIS API

Status: Implemented, hardware items open — depends on `javis_api/specs/003` to `006`  
Updated: 2026-11-05

## Context

Every account, home, member, invitation and scene in the app has been in-memory
mock data since spec 012. The Go API now implements all of them. The owner asked
for every feature that exists in the app to be connected.

## Goal

With `--dart-define=JAVIS_API_URL=…` the app uses the API for accounts, homes,
zones, members, invitations, the device registry and scenes, and survives a
restart signed in. Without it the app keeps working as the offline demo.

## Non-goals

- A lock integration: the hardware path is undecided (D4), so the lock stays a
  labelled preview. `can_unlock` from the API does gate the preview.
- Voice: out of scope in `PROJECT_SPEC.md`.
- A real SMS provider (D5): codes come from the API's debug mode.
- Sharing a Tuya device with other people's phones. The registry records who
  owns a device; a member's phone sees a light only if its own Tuya session does.
- Offline caching of homes. Offline shows a calm message with retry.

## Design

`lib/backend/` holds one interface, `JavisBackend`, with two implementations:

- `ApiBackend` calls the API through `ApiClient` (`dart:io`, no new package).
- `DemoBackend` is the former mock data, behind the same interface.

Stores have one code path and do not know which backend they have. This mirrors
how `JAVIS_LIGHTING_PROVIDER` selects a `LightingService`.

Failures are one type, `BackendFailure(code)`: the API's error code, or `offline`
and `unknown`. `AppLocalizations.failure` is the only place that turns a code into
words, so no screen shows a code or English server text.

The session token lives in the iOS Keychain through a small method channel
(`SessionVault`), this device only. It is never logged. A 401 `unauthorized` from
any request clears it and returns to the welcome screen.

## User flow

1. Launch with a stored session: `GET /v1/me`, then homes. Offline shows a retry
   screen, not the welcome screen, so a saved session is not lost.
2. Sign-in: `POST otp/request`, then `otp/verify`. In debug mode the OTP screen
   shows the code. A user with no name goes to the profile step, a user with a
   name and no home goes to create home, anyone else enters the home.
3. Home data is loaded per home: details, members and devices. Scenes load for the
   active home. All of it refreshes when the app returns to the foreground.
4. Reversible edits (rename, member rights, removals) show at once and revert with
   a calm message on failure. Creating things waits for the server, with loading
   on the control.

## Rules taken from the API

The app reflects these and the API enforces them (`javis_api/specs/005`):

- Only the owner can invite an admin, grant unlock, or change a role or right.
- Owner and admin can invite and remove; an admin cannot remove an admin.
- The owner cannot leave; everyone else can.
- A home with devices cannot be deleted (409 `home_has_devices`).

## Devices

With the API and a real lighting provider, a home shows only the lights in its
registry. A light the provider reports that no loaded home has is claimed for the
active home by an owner or admin, so an already paired bulb does not vanish. A 409
`device_claimed` means another home owns it: the light stays hidden. Names and
zones chosen after pairing are saved with `PATCH`.

With the demo lighting provider there is nothing real to register, so lights stay
unregistered and show in every home. `external_ref` is the provider's device id.

## Acceptance criteria

- [x] Sign-in, restart still signed in, sign-out, expired session.
- [x] New user: profile, create home with zones, then the dashboard.
- [x] Rename home, add zone, switch home, delete an empty home.
- [x] Invite, see the invite on the second account, accept, decline.
- [x] Owner changes role and unlock right; remove a member; leave a home.
- [x] Admins do not see the admin role or the unlock switch when inviting.
- [x] Scenes: defaults appear, create, edit, delete, run, and the run is recorded.
- [x] Members cannot edit scenes or add devices; unlock follows `can_unlock`.
- [x] Offline, rate limit and every API error show a calm localized message.
- [x] The demo build behaves as before.

Removing a member asks first; revoking a pending invite does not, because it can
simply be sent again. A wrong OTP keeps the keyboard attached, so the next digits
arrive without a tap.

## Risks

- A physical iPhone cannot reach `127.0.0.1`; use the Simulator or a LAN URL.
- If a bulb is removed from Tuya but the registry delete fails, the home keeps a
  registry row with no light, which blocks deleting the home until it is removed.
- Scene runs on physical bulbs use the same commands as the light screens but are
  unverified on hardware.
- Very fast injected typing dropped digits in the formatted phone field on the
  debug Simulator build; OTP and plain text fields did not. Check by hand on a
  physical iPhone in a release build.

## Verification

Run on 2026-11-05.

- `dart format --output=none --set-exit-if-changed .`, `flutter analyze` and
  `flutter test` pass.
- `test/backend/live_api_test.dart` passed against the real API and a throwaway
  PostgreSQL 17 database: homes, zones, default and custom scenes, invites,
  accept, decline, revoke, roles, forbidden paths, device claim and label, 409
  paths, leave, session restore and sign-out.
- Simulator (iPhone 15 Pro, iOS 17) debug build against the local API, each step
  matched to its request in the API log:
  - OTP request, wrong code, right code, profile, create home with zones.
  - Restart still signed in from the Keychain; sign-out; existing number goes
    straight to the dashboard.
  - Scene run and its last-used time, scene create, edit, delete.
  - Rename home, add zone, second home, switch, delete an empty home.
  - Invite with a masked number, second account sees it, accept.
  - A member sees no unlock, add device, rename, add zone or invite controls, and
    can leave; with no home left the dashboard offers to create one.
  - Owner changes role and unlock right, removes a member; a member joining on
    another device appears on resume.
  - API stopped at launch shows the retry screen, still signed in; retry recovers.
  - Thai and English; light and dark; accessibility-large text.

Not checked on the Simulator, covered only as listed:

- Expired session mid-use, rate limit and other API errors: `api_client_test.dart`.
- Decline, and admin-only limits when inviting: `live_api_test.dart` and the code
  path; no Simulator run.
- The demo build: the widget tests run on it; not launched on the Simulator.
- Real lights, scenes on physical bulbs and device claiming on a real provider:
  the Simulator has no Tuya SDK, so it used demo lights. `home_store_test.dart`
  covers the claim rules against a fake.

Run on 2026-11-06 on a physical iPhone, as a profile build with `JAVIS_API_URL`
set to the Mac's LAN address and `JAVIS_LIGHTING_PROVIDER=tuya`, against the local
API over plain HTTP. The API log and the local database match each step:

- OTP request, wrong code, right code, profile, and create home.
- The paired light was claimed through `POST /v1/homes/{homeId}/devices`, and the
  database holds its registry row.
- Sign-out, then the same number returned to the saved home. The owner confirmed
  that nothing had to be entered again.

Not checked on the physical iPhone: scene runs on the real light, and whether the
light was online during this run.

## Current status

Implemented for accounts, homes, members, invites, scenes and the device registry.
Open and tracked elsewhere: the lock is a labelled preview until the hardware
decision (D4), SMS has no provider yet (D5, OTP debug mode only), voice is a
preview, and Tuya device sharing with other members is not built.
