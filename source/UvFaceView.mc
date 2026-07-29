import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
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
        var conditions = Weather.getCurrentConditions();
        if (conditions != null) {
            uv = conditions.uvIndex;   // Float or null
        }

        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var text = (uv == null) ? "--" : uv.format("%.0f");

        if (_lowPower) {
            // Always-on display: keep it dim and small, and nudge the
            // position every minute to satisfy AMOLED burn-in protection.
            var shift = ((System.getClockTime().min % 3) - 1) * 12;
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy + shift, Graphics.FONT_NUMBER_MILD, text,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        // --- Active mode: big number, colored by WHO UV scale ---
        dc.setColor(uvColor(uv), Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 18, Graphics.FONT_NUMBER_THAI_HOT, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 70, Graphics.FONT_SMALL, "UV INDEX",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 100, Graphics.FONT_XTINY, uvLabel(uv),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Standard WHO color scale.
    private function uvColor(uv as Float?) as Number {
        if (uv == null)  { return Graphics.COLOR_LT_GRAY; }
        if (uv < 3)      { return Graphics.COLOR_GREEN;   }  // Low
        if (uv < 6)      { return Graphics.COLOR_YELLOW;  }  // Moderate
        if (uv < 8)      { return Graphics.COLOR_ORANGE;  }  // High
        if (uv < 11)     { return Graphics.COLOR_RED;     }  // Very high
        return 0xAA55FF;                                     // Extreme (violet)
    }

    private function uvLabel(uv as Float?) as String {
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
