# KickrBikeGears

A Garmin Connect IQ data field showing the virtual front and rear gear positions of a Wahoo KICKR BIKE SHIFT. Maintained by [Benyba](https://github.com/Benyba), with optional support through [Buy Me a Coffee](https://buymeacoffee.com/benyba).

> Publication draft: intended as the root README of a future `KickrBikeGears` repository. The repository has not been created, a license has not been selected, and a Connect IQ Store release has not been published. Resolve these items before removing this note.

## Features

- **Front and rear positions**: English labels, orange selected gears and equally thin bars.
- **Adaptive graphics**: layouts include three front positions and thirteen rear positions; actual counts come from the bike.
- **Compact view**: numerical positions when the data field is too small for both graphics.
- **BLE connection**: automatic discovery and reconnection attempts after a detected connection loss.
- **Local operation**: no app account, backend, advertising, analytics or payment integration.

## Hardware and status

This project targets KICKR BIKE SHIFT. Other KICKR models and other smart bikes are not claimed as supported.

The development manifest lists Edge 850 and Edge 540, but that is not a claim that both have completed hardware validation. Record actual release-build test results before advertising supported devices; no Garmin SDK compilation or hardware tests were performed by the assistant preparing these files.

## Build and install

Use your existing working Monkey C project and the Garmin Connect IQ SDK with the VS Code extension. Preserve your app identifier, resources and private signing key; Garmin requires the same signing key for Store updates ([security guidance](https://developer.garmin.com/connect-iq/core-topics/security/)).

1. Include `source/KickrBikeGears.mc` and, optionally, `source/KickrGearTests.mc`.
2. Check `manifest.xml`, `monkey.jungle` and resources in your local project. Confirm any required launcher-icon resources before building.
3. For a release build, keep `DEMO = false` and `DEBUG = false`.
4. Compile and test for each device you intend to support.
5. For Store submission, use `Monkey C: Export Project` to create the signed `.iq` package ([Garmin submission procedure](https://developer.garmin.com/connect-iq/submit-an-app)).

Never publish your private signing key, credentials, diagnostic logs or unrelated personal files. Exclude local build outputs from the source repository; supply any intended release packages separately after review.

## Use

Add the field to an indoor cycling data page and use a large field for both graphics. Wake the bike, wait for the connection, then change a gear when “Shift a gear” appears.

The field uses its own BLE connection for gear data. Native ANT+ trainer pairing can remain in place.

The numbers are gear positions, not tooth counts or a calculated ratio. The field neither controls resistance nor shifts gears, and it does not record gear values to FIT files.

## Optional support

KickrBikeGears is free to use. All features are available without payment.

If you find it useful, you can [buy me a coffee](https://buymeacoffee.com/benyba) to support development. Contributions are entirely voluntary, do not unlock any features and are processed externally, not by the data field.

## Credits and license

Thanks to stareat for the public [KICKR BIKE SHIFT display implementation](https://github.com/stareat/wahoo-kickr-bike-shift-display), and to jonasbark, MattW2 and Benyba for the [OpenBikeControl BLE discovery discussion](https://github.com/OpenBikeControl/bikecontrol/issues/42). Include the companion `ACKNOWLEDGEMENTS.md` at the repository root for fuller attribution.

License selection is pending. The upstream protocol-reference repository is GPL-3.0; do not describe this draft as MIT-licensed or ready for unrestricted reuse without resolving the licensing review ([upstream license](https://github.com/stareat/wahoo-kickr-bike-shift-display/blob/main/LICENSE)).

KickrBikeGears is independent and unofficial. It is not affiliated with, sponsored by or endorsed by Wahoo or Garmin.

## Support and privacy

Before publication, add a working support channel and the URL of the completed privacy notice here. Never ask users to post signing keys, credentials or unrelated activity records; keep privacy requests out of public issue trackers.
