# Changelog

Notable changes to Notch Music are documented in this file.

## Unreleased

### Added

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

## 1.0.0 - 2026-08-17

- Initial release of the compact and expanded notch player.
- Playback controls, seeking, dynamic reveal animations, and Liquid Glass.
- Built-in and external display layouts and configurable behavior.
