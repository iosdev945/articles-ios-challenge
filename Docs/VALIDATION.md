# Validation

Local tooling: Xcode 27.0 (27A266a), Swift 6.4 compiler in Swift 5 language mode, CocoaPods 1.16.2. The app targets iOS 18.0. Xcode 26 is the challenge requirement and is selected by CI; it was not installed locally. Available simulators run iOS 18.3 or iOS 27.0, not iOS 26 itself.

[Final fresh-checkout CI run](https://github.com/iosdev945/articles-ios-challenge/actions/runs/37892146946): **passed**, Xcode 26.6 using the iPhoneSimulator 26.5 SDK; 29 unit tests and 7 UI tests, zero failures. The final source revision validated by that run is `66e876f`.

## Automated coverage

29 unit tests cover decoding and fallbacks, URL/date validation, identity, all 79 captured API articles, real disk persistence, manager error/offline behavior, concurrent refresh coalescing, bookmarks, HTTP validation/parsing failures and bundled UIKit resources. Seven UI tests cover navigation, layouts, search, bookmarks, missing data, offline retry/cached browsing, error/empty states and maximum text size.

Offline UI scenarios inject an in-memory snapshot; actual Cache persistence is tested separately. Connectivity forwarding is tested at manager level. Physical-device radio transitions remain a manual check.

| Device/runtime | Result |
| --- | --- |
| iPhone 16e / iOS 18.3 | 29 unit + 7 UI tests passed |
| iPad (A16) / iOS 18.3 | 29 unit + 7 UI tests passed; final spacing/search checks passed |
| iPhone 18 Pro / iOS 27.0 | Not validated: simulator startup stalled |
| Xcode 26.6 / compatible iPhone simulator in CI | 29 unit + 7 UI tests passed |

The first iPad/modern runs were interrupted by insufficient host disk space. Task-generated failed build artifacts were removed, and subsequent runs are performed serially. This is an environment limitation, not an asserted application test pass.

## Visual review

Test screenshots are attached to result bundles and representative images are saved under `Docs/Screenshots/`. A normal iPad launch also verified live API article loading and real image downloads. Review list/grid spacing, detail scrolling, image placeholders, offline messages and accessibility text. Exact Figma token/asset matching remains outstanding; no pixel-perfect claim is made. Device testing and iOS 26-specific rendering remain to be reviewed.

## Manual acceptance guide

1. Launch online; inspect real articles and images. Pull to refresh and switch layouts.
2. Open detail, navigate back, bookmark, share and open Safari. Done should return to detail.
3. Load once, enable airplane mode and relaunch. Inspect saved articles, the offline message and uncached-image placeholders.
4. Restore connectivity; verify automatic refresh and continued reading.
5. On a clean install, launch offline. Inspect the offline state and Retry. Use a controlled proxy to test unreadable responses.
6. Inspect missing title/author/description/date, broken images and invalid links. Verify fallbacks and disabled link actions.
7. Use maximum Dynamic Type, VoiceOver and Reduce Motion; verify wrapping, scrolling and accessible controls.
8. Rotate and resize iPad; verify side-by-side reading, selection and compact back navigation.

This guide is not a claim that each step was executed on a physical device.
