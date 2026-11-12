# KickrBikeGears Acknowledgements

KickrBikeGears benefited from publicly shared technical work and community discussions. Thank you to the people who made these resources available.

## Technical references

- **stareat / wahoo-kickr-bike-shift-display**: reference for the Wahoo gearing service and characteristic, and gear-notification fields for front/rear selections and counts. The implementation targets ESP32 displays, not Garmin Connect IQ ([repository](https://github.com/stareat/wahoo-kickr-bike-shift-display), [reference implementation](https://github.com/stareat/wahoo-kickr-bike-shift-display/blob/main/wahoo-kickr-bike-shift-display.ino)).
- **OpenBikeControl / bikecontrol community**: especially jonasbark, MattW2 and Benyba, for sharing KICKR BIKE SHIFT discovery and connection findings. Issue #42 discusses controls and BLE discovery; it is not credited as the gear-packet decoder or as a Garmin implementation ([discussion](https://github.com/OpenBikeControl/bikecontrol/issues/42)).
- **Garmin developer community**: documentation and discussion of Monkey C string comparisons helped diagnose the connection state machine ([string-comparison discussion](https://forums.garmin.com/developer/connect-iq/f/discussion/165666/if-not-works)).

## Independence and licensing

These credits acknowledge useful references, not sponsorship, partnership, endorsement or authorship of this entire app. KickrBikeGears is an independent, unofficial project and is not affiliated with Wahoo or Garmin.

The stareat repository carries GPL version 3. Acknowledgement is not a substitute for fulfilling any applicable license obligations ([upstream license](https://github.com/stareat/wahoo-kickr-bike-shift-display/blob/main/LICENSE)). The license for this project has not yet been selected; complete the provenance and distribution review before publishing this draft.
