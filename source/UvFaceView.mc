import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Weather;

class UvFaceView extends WatchUi.WatchFace {

    // True while the AMOLED is in always-on (low power) mode.
    private var _lowPower as Boolean = false;

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
        var conditions = Weather.getCurrentConditions();
        if (conditions != null) {
            uv = conditions.uvIndex;                 // Float or null
            obsTime = conditions.observationTime;    // Moment or null
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
            var shift = ((System.getClockTime().min % 3) - 1) * scaled(dc, 12);
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy + shift, Graphics.FONT_NUMBER_MILD, text,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        // --- Active mode: big number, colored by WHO UV scale ---
        dc.setColor(uvColor(uvShown), Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - scaled(dc, 30), Graphics.FONT_NUMBER_THAI_HOT, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + scaled(dc, 50), Graphics.FONT_SMALL, "UV INDEX",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + scaled(dc, 80), Graphics.FONT_XTINY, uvLabel(uvShown),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var updatedStr = stalenessLabel(obsTime);
        if (updatedStr != null) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy + scaled(dc, 108), Graphics.FONT_XTINY, updatedStr,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // Vertical offsets were tuned on the 454px Venu 4 45mm screen; scale them
    // so the 390px 41mm screen keeps the same proportions.
    private function scaled(dc as Dc, px as Number) as Number {
        return Math.round(px * dc.getHeight() / 454.0).toNumber();
    }

    // Returns an "updated ..." string, or null if observationTime is unavailable.
    // Rolls over to hours/days so a long phone disconnect does not print
    // something like "updated 632 min ago".
    private function stalenessLabel(obsTime as Time.Moment?) as String? {
        if (obsTime == null) {
            return null;
        }
        var diffSec = Time.now().value() - obsTime.value();
        if (diffSec < 0) {
            diffSec = 0;
        }
        var minAgo = (diffSec / 60).toNumber();
        if (minAgo < 90) {
            return "updated " + minAgo + " min ago";
        }
        var hoursAgo = minAgo / 60;
        if (hoursAgo < 24) {
            return "updated " + hoursAgo + "h ago";
        }
        return "updated 1d+ ago";
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
