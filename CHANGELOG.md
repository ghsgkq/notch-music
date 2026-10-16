# Changelog

Notable changes to Notch Music are documented in this file.

## Unreleased

### Added

- Nyan Cat playback animation with a pixel cat, animated rainbow trail, and a wider compact indicator.

- Selectable playback animations with live previews: bars, wave, bouncing dots, and rotating ring. Paused playback and Reduce Motion stop their animation.

- Optional hover expansion with delayed opening, delayed dismissal, and preservation of manually opened players.
- Artwork-derived accent colors with a manual-color fallback for missing or neutral artwork.
- Launch at login through macOS Service Management, including approval status and registration errors.
- Playback source filtering with a browser exclusion switch, per-app choices, and immediate updates to the current track.
- Per-display position and size adjustments, persisted by display UUID with individual reset controls.

- MIT project license, third-party notices, security policy, and contribution guide.
- Issue templates, Dependabot configuration, and macOS continuous integration.
- Developer ID signing and notarization release helper.

### Changed

- Pinned the media adapter dependency to an exact revision.
- Added legal notices to the generated app bundle.
- Made local ad-hoc signatures structurally verifiable with `codesign`.

### Fixed

- Match notch width, height, and click regions to the current display resolution and scaling.
- Keep wide notches inside the player canvas and use a floating player on notchless built-in displays.
- Convert mouse coordinates before hit testing and keep fractional notch heights flush with the screen top.
- Show the full settings view when opening the native macOS Settings window.

## 1.0.0 - 2026-08-17

- Initial release of the compact and expanded notch player.
- Playback controls, seeking, dynamic reveal animations, and Liquid Glass.
- Built-in and external display layouts and configurable behavior.
