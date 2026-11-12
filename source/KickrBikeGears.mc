// KickrBikeGears 1.0.0: clean daily-use build, based on working revision 0.8.
// Protocol reference (zero-based positions in bytes 2 and 3):
// https://github.com/stareat/wahoo-kickr-bike-shift-display/blob/main/wahoo-kickr-bike-shift-display.ino
using Toybox.Application;
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.Graphics as Gfx;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;

module KickrConfig {
    const VERSION = "1.0.0";
    // true = synthetic gears, clearly labelled DEMO. false = real BLE only.
    const DEMO = false;
    const DEMO_FRONT_COUNT = 3;
    const DEMO_REAR_COUNT = 13;
    // Optional exact advertised name, e.g. "KICKR BIKE SHIFT 720C".
    // Empty = SHIFT name OR advertised Wahoo gearing service.
    // An explicit name remains a strict filter (no service fallback).
    const BIKE_NAME = "";
    // Enable only for troubleshooting. No diagnostic counters on the display.
    const DEBUG = false;
}

// Pure decoder: [displayFront, displayRear, frontCount, rearCount].
// A malformed/unknown packet must not leave an apparently valid old gear.
function decodeKickrGearPacket(data as Lang.ByteArray or Null) as Lang.Array<Lang.Number> or Null {
    if (data == null || data.size() < 6) { return null; }
    var front = data[2];
    var rear = data[3];
    var fronts = data[4];
    var rears = data[5];
    // Defensive prototype limits, NOT an official Wahoo specification.
    if (fronts < 1 || fronts > 4 || rears < 1 || rears > 32) {
        return null;
    }
    if (front >= fronts || rear >= rears) { return null; }
    return [front + 1, rear + 1, fronts, rears];
}

class KickrBikeGearsApp extends Application.AppBase {
    var _ble;
    var _view;

    function initialize() {
        AppBase.initialize();
        _ble = new KickrBle();
        _view = new KickrBikeGearsView(_ble);
    }

    function onStart(state) {
        if (!KickrConfig.DEMO) { _ble.start(); }
    }

    function getInitialView() { return [_view]; }

    function onStop(state) {
        if (!KickrConfig.DEMO) { _ble.stop(); }
    }
}

class KickrBle extends Ble.BleDelegate {
    var gears as Lang.Array<Lang.Number> or Null = null;
    var statusText = "Initializing";
    var _service;
    var _gearUuid;
    var _device = null;
    var _characteristic = null;
    var _state = "idle";
    var _since = 0;
    var _retryAt = 0;
    var _profileReady = false;
    var _active = false;
    var _scanPackets = 0;
    var _scanNamedPackets = 0;
    var _scanLogKeys as Lang.Dictionary = {};
    var _scanLogCount = 0;

    function initialize() {
        BleDelegate.initialize();
        _service = Ble.stringToUuid("a026ee0d-0a7d-4ab3-97fa-f1500f9feb8b");
        _gearUuid = Ble.stringToUuid("a026e03a-0a7d-4ab3-97fa-f1500f9feb8b");
    }

    function log(text) {
        if (KickrConfig.DEBUG) { System.println("KICKR: " + text); }
    }

    function isState(expected as Lang.String) as Lang.Boolean {
        // Monkey C ==/!= do not compare String contents.
        return _state.equals(expected);
    }

    function setState(state, text) {
        _state = state;
        _since = System.getTimer();
        statusText = text;
        log(text);
        WatchUi.requestUpdate();
    }

    function start() {
        _active = true;
        try {
            log("Version " + KickrConfig.VERSION + "; real BLE; exact name filter=" + KickrConfig.BIKE_NAME);
            Ble.setDelegate(self);
            setState("register", "Initializing");
            Ble.registerProfile({
                :uuid => _service,
                :characteristics => [{
                    :uuid => _gearUuid,
                    :descriptors => [Ble.cccdUuid()]
                }]
            });
        } catch (e) {
            log(e.toString());
            setState("fatal", "BLE profile error");
        }
    }

    function stop() {
        log("APP STOP");
        _active = false;
        _state = "stopped";
        gears = null;
        _characteristic = null;
        try { Ble.setScanState(Ble.SCAN_STATE_OFF); } catch (e) {}
        var old = _device;
        _device = null;
        if (old != null) {
            try { Ble.unpairDevice(old); } catch (e) {}
        }
    }

    function fail(text) {
        if (!_active) { return; }
        gears = null;
        _characteristic = null;
        log("RETRY reason=" + text);
        setState("retry", "Reconnecting...");
        _retryAt = System.getTimer() + 8000;
        try { Ble.setScanState(Ble.SCAN_STATE_OFF); } catch (e) {}
        var old = _device;
        _device = null;
        if (old != null) {
            try { Ble.unpairDevice(old); } catch (e) {}
        }
    }

    function scan() {
        if (!_active || !_profileReady) { return; }
        try {
            var available = Ble.getAvailableConnectionCount();
            log("SCAN REQUEST available=" + available.toString());
            if (available < 1) {
                fail("BLE busy");
                return;
            }
            _scanPackets = 0;
            _scanNamedPackets = 0;
            _scanLogKeys = {};
            _scanLogCount = 0;
            setState("scan", "Searching SHIFT");
            Ble.setScanState(Ble.SCAN_STATE_SCANNING);
        } catch (e) {
            log(e.toString());
            fail("BLE scan error");
        }
    }

    // Keep the working 0.8 compute/onUpdate watchdog paths, without counters.
    // State/time guards avoid duplicate transitions. No free-running timer.
    function tick() {
        if (!_active) { return; }
        var now = System.getTimer();
        if (isState("retry") && now >= _retryAt) {
            scan();
        } else if ((isState("scan") || isState("pair") ||
                    isState("subscribe")) && now - _since > 30000) {
            if (KickrConfig.DEBUG && isState("scan")) {
                log("SCAN SUMMARY packets=" + _scanPackets.toString() +
                    " named=" + _scanNamedPackets.toString());
            }
            fail("BLE timeout");
        } else if (isState("register") && now - _since > 15000) {
            setState("fatal", "Profile timeout");
        }
        // Do not expire a gear just because no shift occurred:
        // notifications are event-driven, not a heartbeat.
    }

    function onProfileRegister(uuid, result) {
        if (!_active || !uuid.equals(_service)) { return; }
        if (result != Ble.STATUS_SUCCESS) {
            setState("fatal", "Profile error " + result.toString());
            return;
        }
        _profileReady = true;
        scan();
    }

    function onScanStateChange(scanState, result) {
        log("SCAN STATE " + scanState.toString() + " status=" + result.toString());
        if (_active && isState("scan") && result != Ble.STATUS_SUCCESS) {
            fail("Scan error " + result.toString());
        }
    }

    // Bounded diagnostics: at most 24 distinct advertising payloads per scan.
    // Counts represent received packets, NOT the number of distinct devices.
    function logScan(scanResult as Ble.ScanResult, name as Lang.String or Null, services as Lang.String) {
        if (!KickrConfig.DEBUG || _scanLogCount >= 24) { return; }
        var rawText = "";
        var raw = scanResult.getRawData();
        if (raw != null) {
            for (var i = 0; i < raw.size() && i < 64; i += 1) {
                rawText += raw[i].format("%02X");
            }
        }
        var label = name == null ? "<no name>" : name;
        var key = label + "|" + services + "|" + rawText;
        if (_scanLogKeys.hasKey(key)) { return; }
        _scanLogKeys[key] = true;
        _scanLogCount += 1;
        log("SCAN name=" + label + " rssi=" + scanResult.getRssi().toString());
        log("SERVICES " + services);
        log("ADV " + rawText);
    }

    function onScanResults(results as Ble.Iterator) as Void {
        if (!_active || !isState("scan")) { return; }
        for (var item = results.next(); item != null; item = results.next()) {
            // Iterator.next() returns Object or Null, not ScanResult.
            // This callback's iterator contains ScanResult instances.
            var scanResult = item as Ble.ScanResult;
            var name = scanResult.getDeviceName();
            if (KickrConfig.DEBUG) {
                _scanPackets += 1;
                if (name != null) { _scanNamedPackets += 1; }
            }
            var hasGearService = false;
            var serviceText = "";
            var services = scanResult.getServiceUuids();
            if (services != null) {
                for (var entry = services.next(); entry != null; entry = services.next()) {
                    var uuid = entry as Ble.Uuid;
                    if (uuid.equals(_service)) { hasGearService = true; }
                    if (KickrConfig.DEBUG) { serviceText += uuid.toString() + " "; }
                }
            }
            if (KickrConfig.DEBUG) { logScan(scanResult, name, serviceText); }
            var matches = false;
            var reason = "";
            if (KickrConfig.BIKE_NAME.length() > 0) {
                matches = name != null && name.equals(KickrConfig.BIKE_NAME);
                reason = "exact name";
            } else {
                matches = name != null && name.find("KICKR BIKE SHIFT") == 0;
                reason = "SHIFT name";
                if (!matches && hasGearService) {
                    matches = true;
                    reason = "Wahoo gearing service";
                }
            }
            if (!matches) { continue; }
            log("MATCH via " + reason);
            setState("pair", "Connecting...");
            try {
                Ble.setScanState(Ble.SCAN_STATE_OFF);
                _device = Ble.pairDevice(scanResult);
                log(_device == null ? "PAIR returned null" : "PAIR accepted");
                if (_device == null) { fail("Connection failed"); }
            } catch (e) {
                log(e.toString());
                fail("Connection error");
            }
            return;
        }
    }

    function onConnectedStateChanged(device, state) {
        log("CONNECTION state=" + state.toString());
        if (!_active || _device == null || !device.equals(_device)) { return; }
        if (state != Ble.CONNECTION_STATE_CONNECTED) {
            fail("SHIFT disconnected");
            return;
        }
        gears = null;
        try {
            var service = device.getService(_service);
            if (service == null) { fail("Service missing"); return; }
            _characteristic = service.getCharacteristic(_gearUuid);
            if (_characteristic == null) { fail("Data missing"); return; }
            var cccd = _characteristic.getDescriptor(Ble.cccdUuid());
            if (cccd == null) { fail("CCCD missing"); return; }
            setState("subscribe", "Connecting...");
            // Only a notification subscription. No resistance/gear commands.
            cccd.requestWrite([0x01, 0x00]b);
        } catch (e) {
            log(e.toString());
            fail("Subscription error");
        }
    }

    function onDescriptorWrite(descriptor, result) {
        if (!_active || !isState("subscribe")) { return; }
        if (!descriptor.getCharacteristic().getUuid().equals(_gearUuid)) { return; }
        if (result != Ble.STATUS_SUCCESS) {
            fail("CCCD error " + result.toString());
            return;
        }
        // No forced read: the reference implementation uses notifications only.
        setState("ready", gears == null ? "Shift a gear" : "Connected");
    }

    function onCharacteristicChanged(characteristic as Ble.Characteristic, value as Lang.ByteArray) as Void {
        if (!_active || _device == null ||
            (!isState("subscribe") && !isState("ready")) ||
            !characteristic.getUuid().equals(_gearUuid)) { return; }
        if (KickrConfig.DEBUG) {
            var raw = "";
            for (var i = 0; i < value.size() && i < 20; i += 1) {
                raw += value[i].format("%02X") + " ";
            }
            log("RX " + raw);
        }
        gears = decodeKickrGearPacket(value);
        statusText = gears == null ? "Data unavailable" : "Connected";
        WatchUi.requestUpdate();
    }
}

class KickrBikeGearsView extends WatchUi.DataField {
    var _ble as KickrBle;
    var _demoTick = 0;
    var _demoGears as Lang.Array<Lang.Number> = [
        1, 1, KickrConfig.DEMO_FRONT_COUNT, KickrConfig.DEMO_REAR_COUNT
    ];

    function initialize(ble as KickrBle) {
        DataField.initialize();
        _ble = ble;
    }

    function compute(info) {
        if (KickrConfig.DEMO) {
            _demoTick += 1;
            _demoGears = [
                ((_demoTick / (2 * KickrConfig.DEMO_REAR_COUNT)).toNumber()
                    % KickrConfig.DEMO_FRONT_COUNT) + 1,
                ((_demoTick / 2).toNumber() % KickrConfig.DEMO_REAR_COUNT) + 1,
                KickrConfig.DEMO_FRONT_COUNT, KickrConfig.DEMO_REAR_COUNT
            ];
        } else {
            _ble.tick();
        }
    }

    function onLayout(dc) {
        // All drawing is relative to the actual field, not screen resolution.
    }

    function fittedText(dc, text, y, maxWidth, font) {
        var shown = text;
        while (shown.length() > 0 &&
               dc.getTextWidthInPixels(shown, font) > maxWidth) {
            shown = shown.substring(0, shown.length() - 1);
        }
        dc.drawText(dc.getWidth() / 2, y, font, shown, Gfx.TEXT_JUSTIFY_CENTER);
    }

    // Schematic sizes, not actual tooth counts. Selected position is 1-based.
    function drawGearGroup(dc, x, y, width, height, count, selected, front, step, fg, bg) {
        // Shared step ensures identical front/rear bar widths.
        var barWidth = step - 3;
        if (barWidth < 2 || height < 8) { return; }
        var startX = x + ((width - count * step) / 2).toNumber();
        var minHeight = (height / 4).toNumber();
        if (minHeight < 6) { minHeight = 6; }
        for (var i = 0; i < count; i += 1) {
            var bh = height;
            if (count > 1) {
                if (front) {
                    // Chainrings: small to large, left to right.
                    bh = (height / 2 + height * i / (2 * (count - 1))).toNumber();
                } else {
                    // Cassette: large to small, left to right.
                    bh = height - ((height - minHeight) * i / (count - 1)).toNumber();
                }
            }
            var bx = startX + i * step + 1;
            var by = y + height - bh;
            if (i + 1 == selected) {
                dc.setColor(Gfx.COLOR_ORANGE, bg);
                dc.fillRectangle(bx, by, barWidth, bh);
            }
            dc.setColor(fg, bg);
            dc.drawRectangle(bx, by, barWidth, bh);
        }
    }

    function onUpdate(dc) {
        if (!KickrConfig.DEMO) { _ble.tick(); }
        var w = dc.getWidth();
        var h = dc.getHeight();
        var bg = getBackgroundColor();
        var fg = bg == Gfx.COLOR_BLACK ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK;
        dc.setColor(fg, bg);
        dc.clear();
        var g = KickrConfig.DEMO ? _demoGears : _ble.gears;
        var title = KickrConfig.DEMO ? "DEMO - KICKR" : "KICKR SHIFT";
        var small = Gfx.FONT_XTINY;
        var sh = dc.getFontHeight(small);
        var value = g == null ? "-- / --" :
            g[0].toString() + " / " + g[1].toString();
        // Use a text font: number-only fonts need not contain the "/" glyph.
        var font = Gfx.FONT_LARGE;
        if (dc.getTextWidthInPixels(value, font) > w - 12 ||
            dc.getFontHeight(font) > h - 2 * sh - 8) {
            font = Gfx.FONT_MEDIUM;
        }
        if (dc.getTextWidthInPixels(value, font) > w - 12) {
            font = Gfx.FONT_SMALL;
        }
        var vh = dc.getFontHeight(font);

        // Compact fields: keep DEMO explicit, prioritize the numeric value.
        if (h < sh + vh + sh + 14) {
            fittedText(dc, title, 0, w - 6, small);
            var compact = g == null ?
                (KickrConfig.DEMO ? "DEMO" : _ble.statusText) : value;
            fittedText(dc, compact, sh, w - 8, g == null ? small : font);
            return;
        }
        fittedText(dc, title, 2, w - 8, small);
        var yValue = sh + 4;
        fittedText(dc, value, yValue, w - 12, font);
        var detail = g == null ? _ble.statusText :
            "Front " + g[0].toString() + "/" + g[2].toString() +
            "  Rear " + g[1].toString() + "/" + g[3].toString();
        fittedText(dc, detail, h - sh - 2, w - 8, small);

        var yTop = yValue + vh + 5;
        var yBottom = h - sh - 7;
        if (g != null && yBottom - yTop >= 14) {
            var gap = 14;
            var usable = w - 16 - gap;
            var frontWidth = (usable / 4).toNumber();
            var rearWidth = usable - frontWidth;
            var sharedStep = (rearWidth / g[3]).toNumber();
            var frontStep = (frontWidth / g[2]).toNumber();
            if (frontStep < sharedStep) { sharedStep = frontStep; }
            var frontX = 8;
            var rearX = frontX + frontWidth + gap;
            // Labels on large fields; numeric front/rear positions stay visible
            // on compact fields where a graph or its labels cannot fit.
            if (w >= 180 && yBottom - yTop >= sh + 32) {
                var frontLabel = "FRONT";
                var rearLabel = "REAR";
                if (dc.getTextWidthInPixels(frontLabel, small) > frontWidth) {
                    frontLabel = "F";
                }
                if (dc.getTextWidthInPixels(rearLabel, small) > rearWidth) {
                    rearLabel = "R";
                }
                dc.drawText(frontX + frontWidth / 2, yTop, small,
                    frontLabel, Gfx.TEXT_JUSTIFY_CENTER);
                dc.drawText(rearX + rearWidth / 2, yTop, small,
                    rearLabel, Gfx.TEXT_JUSTIFY_CENTER);
                yTop += sh + 4;
            }
            var graphHeight = yBottom - yTop;
            dc.setColor(fg, bg);
            dc.drawLine(frontX + frontWidth + gap / 2, yTop,
                frontX + frontWidth + gap / 2, yBottom);
            drawGearGroup(dc, frontX, yTop, frontWidth, graphHeight,
                g[2], g[0], true, sharedStep, fg, bg);
            drawGearGroup(dc, rearX, yTop, rearWidth, graphHeight,
                g[3], g[1], false, sharedStep, fg, bg);
        }
    }
}
