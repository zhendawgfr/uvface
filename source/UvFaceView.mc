import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;
import Toybox.Weather;

class UvFaceView extends WatchUi.WatchFace {

    // True while the AMOLED is in always-on (low power) mode.
    private var _lowPower as Boolean = false;

    // Small font for the forecast-bar hour labels, created lazily.
    // FONT_XTINY is the smallest fixed font, so going smaller needs a
    // vector font; falls back to FONT_XTINY where unsupported.
    private var _barFont as Graphics.FontType? = null;

    function initialize() {
        WatchFace.initialize();
    }

    // Called roughly once per minute in low power mode,
    // and once per second (or on demand) in high power mode.
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // --- Get the UV index for the current location ---
        var uv = null;
        var obsTime = null;
        var obsName = null;
        var conditions = Weather.getCurrentConditions();
        if (conditions != null) {
            uv = conditions.uvIndex;                          // Float or null
            obsTime = conditions.observationTime;             // Moment or null
            // Deprecated ("may be removed after System 11") but has no
            // replacement — Weather exposes no other location name, and
            // reverse-geocoding coordinates would need network code.
            // Needs the Positioning permission; degrades to null without it,
            // which provenanceLabel() already handles.
            obsName = conditions.observationLocationName;     // String or null
        }

        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;

        // Round once, then classify on the rounded value, so the number on
        // screen always matches its color and label (2.7 shows as 3, and 3 is
        // "moderate" on the WHO scale, not "low").
        var uvShown = (uv == null) ? null : Math.round(uv);
        var text = (uvShown == null) ? "--" : uvShown.format("%.0f");

        if (_lowPower) {
            // Always-on display: keep it dim and small, and nudge the
            // position every minute to satisfy AMOLED burn-in protection.
            // The clock and the number shift together as one block.
            var shift = ((System.getClockTime().min % 3) - 1) * scaled(dc, 12);
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - scaled(dc, 75) + shift, Graphics.FONT_SMALL, clockString(),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(cx, cy + shift, Graphics.FONT_NUMBER_MILD, text,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        // --- Active mode: clock on top, big number colored by WHO UV scale.
        // At night (sun below the horizon) the number gives way to a moon —
        // see nightInfo() for the exact rule. ---
        var hourly = Weather.getHourlyForecast();
        var night = nightInfo(conditions, hourly);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        // Number font (not a text font) so the time reads at a glance —
        // raised from FONT_MEDIUM after a store review asked for a bigger clock.
        dc.drawText(cx, cy - scaled(dc, 160), Graphics.FONT_NUMBER_MILD, clockString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        if (night != null) {
            drawCrescent(dc, cx, cy - scaled(dc, 30));
        } else {
            dc.setColor(uvColor(uvShown), Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy - scaled(dc, 30), Graphics.FONT_NUMBER_THAI_HOT, text,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + scaled(dc, 45), Graphics.FONT_XTINY, "UV INDEX",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + scaled(dc, 70), Graphics.FONT_XTINY,
            (night != null) ? "night" : uvLabel(uvShown),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Same slot, different job: by day it says where the data came from,
        // by night it says when UV becomes relevant again (line omitted when
        // the forecast horizon never leaves zero).
        var lineStr = (night != null) ? uvReturnLabel(night[0])
                                      : provenanceLabel(obsTime, obsName);
        if (lineStr != null) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy + scaled(dc, 95), Graphics.FONT_XTINY, lineStr,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        drawForecastBars(dc, cx, cy + scaled(dc, 168), hourly, night != null);
    }

    // Up to 6 one-hour UV forecast bars along the bottom (next ~6 hours),
    // height proportional to UV (capped at 11), colored by the WHO scale,
    // with the hour digit under each bar (12/24h per device setting).
    // The Weather API only provides hourly forecasts, so one bar = one hour;
    // finer bars would just fake precision the data does not have.
    // A null-UV hour gets a dark gray baseline stub. Skipped entirely when
    // no forecast is available. Active mode only — AOD stays minimal.
    // In night mode (skipZeroLead) the zero hours between now and the next
    // UV are dropped, so the bars preview the coming morning instead of
    // drawing a row of flat stubs; if the horizon never leaves zero the row
    // is omitted entirely.
    private function drawForecastBars(dc as Dc, cx as Number, baseY as Number,
            hourly as Array<Weather.HourlyForecast>?, skipZeroLead as Boolean) as Void {
        if (hourly == null) {
            return;
        }

        var nowVal = Time.now().value();
        var started = !skipZeroLead;
        var uvs = [] as Array<Float?>;
        var hours = [] as Array<Number>;
        for (var i = 0; i < hourly.size() && uvs.size() < 6; i++) {
            var ft = hourly[i].forecastTime;
            if (ft == null || ft.value() < nowVal) {
                continue;   // skip stale entries still in the array
            }
            var uv = hourly[i].uvIndex;
            if (!started) {
                if (uv == null || Math.round(uv) == 0) {
                    continue;   // night: drop the zero hours before the next UV
                }
                started = true;
            }
            uvs = uvs.add(uv) as Array<Float?>;
            hours = hours.add(Gregorian.info(ft, Time.FORMAT_SHORT).hour) as Array<Number>;
        }
        if (uvs.size() == 0) {
            return;
        }

        var barFont = _barFont;
        if (barFont == null) {
            if (Graphics has :getVectorFont) {
                barFont = Graphics.getVectorFont(
                    {:face => "RobotoRegular", :size => scaled(dc, 18)});
            }
            if (barFont == null) {
                barFont = Graphics.FONT_XTINY;
            }
            _barFont = barFont;
        }

        var barW = scaled(dc, 26);
        var gap  = scaled(dc, 9);
        var maxH = scaled(dc, 55);
        var labelY = baseY + scaled(dc, 20);
        var x = cx - (uvs.size() * barW + (uvs.size() - 1) * gap) / 2;
        for (var i = 0; i < uvs.size(); i++) {
            var uv = uvs[i];
            var h = 2;
            if (uv == null) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            } else {
                var capped = (uv > 11) ? 11.0 : ((uv < 0) ? 0.0 : uv);
                h = Math.round(maxH * capped / 11.0).toNumber();
                if (h < 2) { h = 2; }
                dc.setColor(uvColor(Math.round(uv)), Graphics.COLOR_TRANSPARENT);
            }
            // Rounded corners; radius clamped so short bars stay drawable.
            var r = scaled(dc, 8);
            if (r > h / 2) { r = h / 2; }
            dc.fillRoundedRectangle(x, baseY - h, barW, h, r);

            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x + barW / 2, labelY, barFont,
                displayHour(hours[i]).toString(),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            x += barW + gap;
        }
    }

    // Night-mode hero: a crescent moon where the big UV number normally sits.
    // No Garmin font has a moon glyph and a bitmap would need per-resolution
    // variants, so it is two filled circles: a light gray disc with a black
    // disc punched out toward the upper right (background is always black,
    // so the overlap simply disappears).
    private function drawCrescent(dc as Dc, cx as Number, cy as Number) as Void {
        var r = scaled(dc, 50);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, r);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx + scaled(dc, 22), cy - scaled(dc, 12), scaled(dc, 43));
    }

    // Decides whether the face is in "night mode". The trigger is the sun,
    // not the forecast: night means "now is before today's sunrise or after
    // today's sunset" per Weather.getSunrise/getSunset at the observation
    // location. A zero-UV forecast must NOT trigger it — a cloudy or deep
    // winter day has UV 0 with the sun up, and a moon at noon looks broken.
    // Any missing data (no conditions, no position, null sun times — polar
    // day/night) means "unknown", and unknown never triggers night; the day
    // layout is the safe default. The current UV value is deliberately not
    // consulted: when the sun is down, a nonzero reading is a stale
    // observation, and hiding it is the point.
    //
    // Returns null in day mode. In night mode returns the forecastTime of
    // the first future hour whose UV rounds above 0, or null when the
    // forecast horizon never leaves zero — the caller drops the
    // "UV from ~HH:MM" line and the bars in that case.
    private function nightInfo(conditions as Weather.CurrentConditions?, hourly as Array<Weather.HourlyForecast>?) as [Time.Moment?]? {
        if (conditions == null) {
            return null;
        }
        var pos = conditions.observationLocationPosition;
        if (pos == null) {
            return null;
        }
        var now = Time.now();
        var sunrise = Weather.getSunrise(pos, now);
        var sunset = Weather.getSunset(pos, now);
        if (sunrise == null || sunset == null) {
            return null;
        }
        var nowVal = now.value();
        if (nowVal >= sunrise.value() && nowVal <= sunset.value()) {
            return null;            // sun is up → day
        }

        // Night. Ask the forecast when UV becomes relevant again.
        var firstUv = null;
        if (hourly != null) {
            for (var i = 0; i < hourly.size(); i++) {
                var ft = hourly[i].forecastTime;
                if (ft == null || ft.value() < nowVal) {
                    continue;
                }
                var uv = hourly[i].uvIndex;
                if (uv != null && Math.round(uv) > 0) {
                    firstUv = ft;
                    break;
                }
            }
        }
        return [firstUv];
    }

    // "UV from ~7:00" — when the forecast says UV returns. The ~ is honest:
    // hourly forecast granularity, not an exact sunrise time.
    private function uvReturnLabel(firstUv as Time.Moment?) as String? {
        if (firstUv == null) {
            return null;
        }
        var info = Gregorian.info(firstUv, Time.FORMAT_SHORT);
        return "UV from ~" + displayHour(info.hour) + ":" + info.min.format("%02d");
    }

    // 24h hour → what the user expects to read, honoring the 12/24h setting.
    private function displayHour(h as Number) as Number {
        if (!System.getDeviceSettings().is24Hour) {
            h = h % 12;
            if (h == 0) { h = 12; }
        }
        return h;
    }

    // Current time as HH:MM, honoring the watch's 12/24-hour setting.
    // Watch faces only update once per minute, so no seconds.
    private function clockString() as String {
        var ct = System.getClockTime();
        return displayHour(ct.hour) + ":" + ct.min.format("%02d");
    }

    // Vertical offsets were tuned on the 454px Venu 4 45mm screen; scale them
    // so the 390px 41mm screen keeps the same proportions.
    private function scaled(dc as Dc, px as Number) as Number {
        return Math.round(px * dc.getHeight() / 454.0).toNumber();
    }

    // One data-provenance line: where the observation came from and how old
    // it is — "Paris · 23 min ago". Falls back to "updated 23 min ago" when
    // the location name is missing, to the bare name when the time is, and
    // to null (line not drawn) when both are.
    private function provenanceLabel(obsTime as Time.Moment?, obsName as String?) as String? {
        var when = agoString(obsTime);
        var name = shortLocationName(obsName);
        if (name != null && when != null) {
            return name + " · " + when;
        }
        if (name != null) {
            return name;
        }
        if (when != null) {
            return "updated " + when;
        }
        return null;
    }

    // Returns "N min ago" / "Nh ago" / "1d+ ago", or null if observationTime
    // is unavailable. Rolls over to hours/days so a long phone disconnect
    // does not print something like "632 min ago".
    private function agoString(obsTime as Time.Moment?) as String? {
        if (obsTime == null) {
            return null;
        }
        var diffSec = Time.now().value() - obsTime.value();
        if (diffSec < 0) {
            diffSec = 0;
        }
        var minAgo = (diffSec / 60).toNumber();
        if (minAgo < 90) {
            return minAgo + " min ago";
        }
        var hoursAgo = minAgo / 60;
        if (hoursAgo < 24) {
            return hoursAgo + "h ago";
        }
        return "1d+ ago";
    }

    // Location names can be long ("Saint-Germain-en-Laye, Île-de-France");
    // keep the part before the first comma and hard-cap the length so the
    // line fits the round screen.
    private function shortLocationName(name as String?) as String? {
        if (name == null) {
            return null;
        }
        var comma = name.find(",");
        if (comma != null) {
            var cut = name.substring(0, comma);
            if (cut != null) {
                name = cut;
            }
        }
        if (name.length() > 18) {
            var trimmed = name.substring(0, 16);
            if (trimmed != null) {
                name = trimmed + "..";
            }
        }
        return name;
    }

    // Standard WHO color scale.
    // Takes the rounded UV value, so `Numeric` rather than the raw `Float`.
    private function uvColor(uv as Numeric?) as Number {
        if (uv == null)  { return Graphics.COLOR_LT_GRAY; }
        if (uv < 3)      { return Graphics.COLOR_GREEN;   }  // Low
        if (uv < 6)      { return Graphics.COLOR_YELLOW;  }  // Moderate
        if (uv < 8)      { return Graphics.COLOR_ORANGE;  }  // High
        if (uv < 11)     { return Graphics.COLOR_RED;     }  // Very high
        return 0xAA55FF;                                     // Extreme (violet)
    }

    private function uvLabel(uv as Numeric?) as String {
        if (uv == null)  { return "no data";   }
        if (uv < 3)      { return "low";       }
        if (uv < 6)      { return "moderate";  }
        if (uv < 8)      { return "high";      }
        if (uv < 11)     { return "very high"; }
        return "extreme";
    }

    // AMOLED always-on transitions.
    function onEnterSleep() as Void {
        _lowPower = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _lowPower = false;
        WatchUi.requestUpdate();
    }
}
