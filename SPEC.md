# SPEC — v1.2 night mode

## §G goal

Sun down → UV number pointless. Face swaps to night layout: moon hero + "UV from ~HH:MM" + bars of next nonzero-UV hours. Day layout unchanged. Trigger = sun times (V10, per B1); forecast drives only line + bars content.

## §C constraints

- Stay `Toybox.Weather` only. ⊥ network, ⊥ new permissions, ⊥ config screens. minApiLevel 3.2.0 → 3.3.0 (V11; zero device loss, all 8 targets ≥ CIQ 5.2).
- All logic in `UvFaceView.mc`, single file.
- Black background always. AOD behavior unchanged.
- All new offsets through `scaled(dc, px)`.
- Moon glyph: no font glyph exists → draw crescent w/ `fillCircle` ×2 (lt-gray circle + black offset circle). ⊥ bitmap resource.
- Zero-check on `Math.round(uv)`, not raw float — consistency w/ displayed digits (0.4 displays 0 ∴ counts as 0).

## §V invariants

V1: [superseded by V10 per B1] ~~night ⟺ forecast-zero~~. Forecast ⊥ night trigger — drives only "UV from" line + night bars.
V2: ∃ null ∈ trigger chain (conditions | observationLocationPosition | getSunrise | getSunset) → day layout. Unknown ⊥ night trigger. Covers polar day/night.
V3: [superseded by V10 per B1] current UV value ⊥ input to day/night decision — sun position authoritative; stale nonzero UV at true night hidden by design.
V4: night active hero = crescent + label "night". UV number ⊥ drawn in night active mode. "UV INDEX" caption stays.
V5: night provenance slot (cy+95) = "UV from ~HH:MM" where HH:MM = forecastTime of first future entry w/ round(uv) > 0. Hour through `displayHour()` — honors 12/24h. No such entry ∈ horizon → line omitted.
V6: night bars = ≤6 entries starting at first future entry w/ round(uv) > 0 (leading zero-hours skipped). No nonzero entry → bars row absent.
V7: day bars unchanged: ≤6 future entries from now, zeros drawn as stubs (v1.1 behavior).
V8: AOD render path untouched by night mode — dim number + burn-in shift as today, day or night.
V9: day layout pixel-identical to v1.1 when not night.
V10: night ⟺ position & sunriseToday & sunsetToday all non-null & (now < sunriseToday | now > sunsetToday). Sun position sole trigger — cloudy/winter zero-UV day stays day layout.
V11: minApiLevel = 3.3.0 (getSunrise/getSunset). No new permissions.

## §I interfaces

api: `Weather.getCurrentConditions().uvIndex` → `Float?` (existing)
api: `Weather.getHourlyForecast()` → `Array<HourlyForecast>?`; entry: `.forecastTime` → `Moment?`, `.uvIndex` → `Float?` (existing)
api: `Weather.getSunrise(loc as Position.Location, when as Moment)` → `Moment?` (CIQ 3.3.0)
api: `Weather.getSunset(loc, when)` → `Moment?` (CIQ 3.3.0)
api: `conditions.observationLocationPosition` → `Position.Location?`
manifest: `minApiLevel="3.3.0"`

## §T tasks

id|status|task|cites
T1|x|helper: `nightInfo(uvShown, hourly)` → null (day) | {firstUvMoment: Moment?} (night); single pass over ≤6 future entries|V1,V2,V3
T2|x|night hero: crescent (2× fillCircle) + "night" label, skip UV number|V4,V9
T3|x|"UV from ~HH:MM" line in provenance slot|V5
T4|x|bars: night → start at first nonzero-UV entry, skip leading zeros; none → skip row|V6,V7
T5|x|sim test: day, night, all-null forecast, current-UV-nonzero @ zero forecast, 12h clock, AOD both modes; build all 8 devices|V8,V9
T6|x|docs: CLAUDE.md night-mode facts, README features, store What's New|—
T7|x|night trigger → sun-times: manifest 3.3.0, `nightInfo` gates on getSunrise/getSunset, forecast keeps line+bars roles; build all 8|V2,V10,V11
T8|~|sim re-test: cloudy day (UV 0, sun up) → day; true night → moon; null position → day; docs sync|V2,V10

## §B bugs

id|date|cause|fix
B1|2026-07-30|forecast-zero trigger → moon on cloudy/winter zero-UV day; forecast measures UV, not sun position|V10
