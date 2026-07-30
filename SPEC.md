# SPEC — v1.2 night mode

## §G goal

No meaningful UV now & none coming (next 6h forecast all 0) → UV number pointless. Face swaps to night layout: moon hero + "UV from ~HH:MM" + bars of next nonzero-UV hours. Day layout unchanged. Fully forecast-driven — ⊥ sunrise/sunset API, ⊥ position.

## §C constraints

- Stay `Toybox.Weather` only. ⊥ network, ⊥ new permissions, ⊥ config screens, ⊥ manifest changes (minApiLevel stays 3.2.0).
- All logic in `UvFaceView.mc`, single file.
- Black background always. AOD behavior unchanged.
- All new offsets through `scaled(dc, px)`.
- Moon glyph: no font glyph exists → draw crescent w/ `fillCircle` ×2 (lt-gray circle + black offset circle). ⊥ bitmap resource.
- Zero-check on `Math.round(uv)`, not raw float — consistency w/ displayed digits (0.4 displays 0 ∴ counts as 0).

## §V invariants

V1: night ⟺ round(currentUv) == 0 & hourly forecast non-null & ≥1 future entry & ∀ future entries (≤6, `forecastTime >= now`) uvIndex non-null & round == 0.
V2: currentUv null → day layout ("--"). ∃ null uvIndex ∈ checked entries → day. Unknown ⊥ night trigger.
V3: currentUv round > 0 → day, regardless of forecast. Number on screen ≠ 0 → never hidden.
V4: night active hero = crescent + label "night". UV number ⊥ drawn in night active mode. "UV INDEX" caption stays.
V5: night provenance slot (cy+95) = "UV from ~HH:MM" where HH:MM = forecastTime of first future entry w/ round(uv) > 0. Hour through `displayHour()` — honors 12/24h. No such entry ∈ horizon → line omitted.
V6: night bars = ≤6 entries starting at first future entry w/ round(uv) > 0 (leading zero-hours skipped). No nonzero entry → bars row absent.
V7: day bars unchanged: ≤6 future entries from now, zeros drawn as stubs (v1.1 behavior).
V8: AOD render path untouched by night mode — dim number + burn-in shift as today, day or night.
V9: day layout pixel-identical to v1.1 when not night.

## §I interfaces

api: `Weather.getCurrentConditions().uvIndex` → `Float?` (existing)
api: `Weather.getHourlyForecast()` → `Array<HourlyForecast>?`; entry: `.forecastTime` → `Moment?`, `.uvIndex` → `Float?` (existing)
manifest: unchanged

## §T tasks

id|status|task|cites
T1|x|helper: `nightInfo(uvShown, hourly)` → null (day) | {firstUvMoment: Moment?} (night); single pass over ≤6 future entries|V1,V2,V3
T2|x|night hero: crescent (2× fillCircle) + "night" label, skip UV number|V4,V9
T3|x|"UV from ~HH:MM" line in provenance slot|V5
T4|x|bars: night → start at first nonzero-UV entry, skip leading zeros; none → skip row|V6,V7
T5|~|sim test: day, night, all-null forecast, current-UV-nonzero @ zero forecast, 12h clock, AOD both modes; build all 8 devices|V1,V3,V8,V9
T6|x|docs: CLAUDE.md night-mode facts, README features, store What's New|—

## §B bugs

id|date|cause|fix
