# Release checklist

Complete this checklist before making a release public.

## Legal and repository

- [ ] Confirm that every dependency revision has an explicit redistribution license.
- [ ] Update `THIRD_PARTY_NOTICES.md` when dependency revisions change.
- [ ] Confirm that the repository license and copyright holder are correct.
- [ ] Confirm that no credentials, personal playback data, build output, or logs are tracked.

## Quality

- [ ] Build from a clean checkout.
- [ ] Test Spotify, YouTube Music, and Apple Music playback detection.
- [ ] Test play/pause, previous/next, and progress seeking.
- [ ] Test built-in display, external display, clamshell mode, Spaces, and full screen.
- [ ] Verify compact and expanded layouts with long Korean and English titles.

## Signed distribution

- [ ] Build with a Developer ID Application certificate.
- [ ] Submit the app to Apple's notarization service.
- [ ] Staple and validate the notarization ticket.
- [ ] Confirm `spctl --assess` accepts the app.
- [ ] Record and publish the ZIP SHA-256 checksum.

Use the release helper after configuring a notarytool keychain profile:

```bash
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE="notch-music" \
./Scripts/package-release.sh v1.0.1
```

Do not publish an ad-hoc signed build as a production release.
