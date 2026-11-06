# Real bulb controls

Status: Implemented, hardware checks open
Last updated: 2026-11-06

## Context

The real provider only exposes power (spec 010). Brightness, temperature and color
exist in the UI but are reported as unsupported. The paired bulb's runtime schema
was read from a physical iPhone on 2026-11-05:

| DP | Code | Mode | Type |
|---|---|---|---|
| 20 | `switch_led` | rw | bool |
| 21 | `work_mode` | rw | enum: white, colour, scene, music |
| 22 | `bright_value` | rw | value 10 to 1000 |
| 23 | `temp_value` | rw | value 0 to 1000 |
| 24 | `colour_data` | rw | string, reported as `000003e803e8` |
| 25 | `scene_data` | rw | string |
| 26 | `countdown` | rw | value 0 to 86400 seconds |
| 27 | `music_data` | wr | string |
| 28 | `control_data` | wr | string |
| 29 | `debug_data` | wr | string |
| 30 to 33 | `rhythm_mode`, `sleep_mode`, `wakeup_mode`, `power_memory` | rw | raw |
| 34 | `do_not_disturb` | rw | bool |
| 35, 82, 209, 210 | `switch_gradient`, `candle_mode_data`, `cycle_timing`, `random_timing` | rw | raw |

Category `dj`. This bulb uses `bright_value`, `temp_value` and `colour_data`, with
1000-scale ranges and the 12-digit `hhhhssssvvvv` color string that Tuya documents
for its lighting products.

## Goal

Control brightness, white temperature and color on real bulbs, from what each bulb
reports in its schema, and show state the bulb reports without a reload.

## Non-goals

- Music mode. It needs microphone capture and beat analysis on the phone.
- The bulb's built-in scenes and the raw schedule DPs (`rhythm_mode`, `sleep_mode`,
  `wakeup_mode`, `cycle_timing`, `random_timing`).
- Storing schemas in the API.
- Rewriting DPs whose format is not documented or observed.

## User flow

1. A real bulb shows the same detail screen as the demo: brightness, white or color,
   temperature, swatches and quick looks.
2. Fine color uses hue and saturation sliders below the swatches.
3. A change sent from another app appears on its own.

## Acceptance criteria

- [ ] Capabilities come only from the schema and the reported state of that bulb.
- [ ] A bulb with a different color layout or range never receives a guessed value.
- [ ] Brightness, temperature, white or color, and quick looks change the real bulb.
- [ ] Controls show the state the bulb reports, including color mode.
- [ ] Scenes apply brightness and temperature on the real bulb.
- [ ] Temperature shows a warm-to-cool feel, not an invented Kelvin figure.

## Implementation notes

- `ios/Runner/TuyaLightProfile.swift`: pure mapping between app values and one
  bulb's DPs, without SDK types.
- Both `_v2` and plain codes are accepted; ranges always come from the schema.
- Color is offered only when `work_mode` allows white and colour and the reported
  color string has the 12-digit layout.
- Brightness in color mode is the color's V. In white mode it is the brightness DP.
- `temp_value` has no Kelvin unit, so native maps it to a nominal 2700K to 6500K
  range and marks it with `nominalTemperature`. The UI then hides the figure.

## Risks

- The direction of `temp_value` and the nominal Kelvin range come from Tuya's
  convention and need checking on the bulb.
- `reportedDPs` keeps the last event per bulb, so events missed while the app is in
  the background may leave stale values until the next one.

## Verification

Run on 2026-11-06.

- `dart format --output=none --set-exit-if-changed .`, `flutter analyze` and
  `flutter test` pass, and the iOS profile build passes with the Tuya provider.

Not verified: the controls on the physical bulb. It reported offline in the sessions
where this was tried, so no command has been confirmed on it. `TuyaLightProfile` has
been checked only against the schema read from the iPhone.
