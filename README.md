# KickrBikeGears

A Garmin Connect IQ data field that displays your Wahoo KICKR BIKE SHIFT's virtual front and rear gear positions while you ride. Developed by [Benyba](https://github.com/Benyba), with an English interface and optional support through [Buy Me a Coffee](https://buymeacoffee.com/benyba).

## Features

- **Front and rear positions**: FRONT and REAR labels, orange selection highlights and matching thin bars.
- **Adaptive graphics**: layouts include three front positions and thirteen rear positions; actual counts come from the bike.
- **Compact view**: numerical positions when the data field is too small for both graphics.
- **BLE connection**: automatic discovery and reconnection attempts after a detected connection loss.
- **Local operation**: no app account, backend, advertising, analytics or payment integration.

## Requirements and compatibility

You need a Wahoo KICKR BIKE SHIFT and a Garmin device supported by the build you install. The bike must be awake and have an available Bluetooth Low Energy connection.

The project manifest targets Edge 850 and Edge 540. Declaring a build target does not certify hardware compatibility: test the release build on each intended device and firmware combination.

This is a data field, not a standalone cycling app. Other KICKR models and other smart bikes are not claimed as supported.

## Getting started

After installing a build on your Garmin, add KickrBikeGears to a data page in your indoor cycling profile. Use a large field to display both gear graphics.

1. Wake the bike and open the data page.
2. Wait for the field to connect.
3. When “Shift a gear” appears, change a gear to receive the first reading.
4. Check that the FRONT and REAR values follow your gear changes.

The field uses its own BLE connection for gear information. You can keep your native Garmin ANT+ trainer pairing for other trainer data.

## Status messages and troubleshooting

| Message | Meaning or suggested action |
|---|---|
| `Searching SHIFT` | Searching for a matching bike. Check that it is awake and nearby. |
| `Connecting...` | Establishing the connection or subscribing to notifications. |
| `Shift a gear` | Connected and waiting for the first gear notification. Change a gear once. |
| `Reconnecting...` | A recoverable connection problem was detected. The field will retry. |
| `Data unavailable` | The received gear packet was not recognized as valid. |

If discovery or connection stalls, temporarily close other apps or devices using the bike's BLE connections and try again. The first reading after a new connection may require another gear change.

Automatic discovery is intended for one matching bike nearby. There is no in-app bike picker; developers can use the exact-name configuration described below when needed.

## Limitations

- **Gear positions, not ratios**: the displayed numbers are positions in the configured drivetrain, not tooth counts, speed or calculated gear ratios.
- **Bike-reported gears**: the field does not read a separate training application's virtual gearing.
- **Display only**: no resistance control, gear-change commands or drivetrain configuration.
- **No FIT gear recording**: gear values are displayed live but are not written to activity files by this field.
- **Disconnection detection**: values are cleared after a reported disconnection or invalid gear packet. A silent radio loss still depends on the Garmin system detecting it.

## Build from source

Use the Garmin Connect IQ SDK and the Monkey C extension for Visual Studio Code. Keep the source, manifest, build configuration and required resources together when building.

```text
manifest.xml
monkey.jungle
source/
    KickrBikeGears.mc
    KickrGearTests.mc
resources/
    ...
```

- **Project setup**: open the project folder in VS Code and configure your SDK and private developer signing key. Check that all manifest resources, including any launcher icon, resolve locally.
- **Build configuration**: use the release settings below and choose the exact Garmin model you intend to test.
- **Tests**: `KickrGearTests.mc` contains optional synthetic decoder and state-comparison tests; these do not replace real-bike testing.
- **Hardware checks**: verify initial connection, front/rear changes, disconnection, reconnection, and full and compact layouts.
- **Store export**: use `Monkey C: Export Project` to generate the signed `.iq` package for submission ([Garmin submission procedure](https://developer.garmin.com/connect-iq/submit-an-app)).

### Configuration

The following values are defined in `KickrConfig` in `source/KickrBikeGears.mc`. These are compile-time settings, not a settings screen on the device.

```monkeyc
const VERSION = "1.0.0";
const DEMO = false;
const BIKE_NAME = "";
const DEBUG = false;
```

- **`DEMO`**: synthetic gears for layout testing, visibly labelled DEMO. Leave disabled for real-bike use.
- **`BIKE_NAME`**: leave empty for automatic matching, or set the exact advertised bike name. An explicit name uses a strict match.
- **`DEBUG`**: enables diagnostic logging for troubleshooting. Leave disabled in release builds and inspect logs for personal device information before sharing.

Never commit your private signing key, credentials or personal diagnostic logs. Preserve a secure private backup of the signing key used for your app, since Garmin requires the same key for Store updates ([signing-key guidance](https://developer.garmin.com/connect-iq/core-topics/security/)).

## Privacy and issue reports

The field processes nearby BLE advertisements and bike gear reports locally on your Garmin. It has no cloud backend, advertising or analytics, and diagnostic logging is disabled by default.

If reporting a problem through the repository's issue tracker, include the Garmin model and software version, the bike firmware version, the field version and the exact status message. Do not post passwords, signing keys, payment details or unrelated activity records.

External websites such as GitHub and Buy Me a Coffee operate separately from the field. Payments are not handled by the app, and the app does not check whether you have contributed.

## Optional support

KickrBikeGears is free to use. All features are available without payment.

If you find it useful, you can [buy me a coffee](https://buymeacoffee.com/benyba) to support development. Contributions are entirely voluntary, do not unlock any features and are processed externally, not by the data field.

## Acknowledgements

Thanks to **stareat** for the public [KICKR BIKE SHIFT display implementation](https://github.com/stareat/wahoo-kickr-bike-shift-display), used as a reference for the BLE gearing service and notification fields. Thanks also to the OpenBikeControl community, especially jonasbark, MattW2 and Benyba, for sharing BLE discovery findings in [issue #42](https://github.com/OpenBikeControl/bikecontrol/issues/42).

See `ACKNOWLEDGEMENTS.md` for further technical references and credits. These acknowledgements do not imply sponsorship or endorsement.

## License

This project is licensed under the GNU General Public License v3.0. See the `LICENSE` file at the repository root for the full terms.

The software is provided without warranty, as described in the license. Preserve applicable third-party notices and credits when redistributing it.

## Disclaimer

KickrBikeGears is an independent, unofficial project. It is not affiliated with, sponsored by or endorsed by Wahoo or Garmin; product names are used only to identify compatibility.
