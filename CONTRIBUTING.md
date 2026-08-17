# Contributing to Notch Music

Thanks for helping improve Notch Music.

## Before opening a change

1. Search existing Issues and pull requests for related work.
2. Open an Issue first for behavior changes or large UI changes.
3. Keep each pull request focused on one fix or feature.

## Local development

Requirements:

- macOS 14 or later
- Xcode 26 or later
- Swift 6

Build and launch the app:

```bash
./Scripts/build-app.sh
open "dist/Notch Music.app"
```

Before submitting a pull request, run:

```bash
swift build
./Scripts/build-app.sh
codesign --verify --deep --strict "dist/Notch Music.app"
```

## Pull requests

- Explain what changed and why.
- Include before/after screenshots or a short recording for UI changes.
- Mention the macOS version and display configuration used for testing.
- Do not commit `.build`, `dist`, logs, credentials, or personal playback data.

By contributing, you agree that your contribution is licensed under the MIT
License in this repository.
