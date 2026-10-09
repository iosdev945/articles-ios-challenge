# Challenge audit — 9 October 2026

Source: the complete client challenge supplied by the user. Implementation evidence was inspected against every requirement; implementation does not imply full visual or physical-device verification.

| Requirement | Finding | Evidence |
| --- | --- | --- |
| Swift, UIKit, MVC, Storyboards and reusable XIBs | Implemented | Main storyboard, ArticleCell and ArticleHeaderView XIBs; models, managers and controllers are separate |
| Hosted self-contained SwiftUI component | Implemented | ArticleStateView embedded by StatePresenter using UIHostingController |
| iOS 18 minimum, iPhone and iPad, Xcode 26 | Implemented and tested | Deployment target 18; device family 1,2; earlier Xcode 26.6 CI passed 29 unit and 7 UI tests |
| All six required CocoaPods | Implemented | Alamofire, XCGLogger, Swinject, ReachabilitySwift, Kingfisher and Cache; committed lockfiles |
| Pixel-perfect Figma match | Outstanding | Colours and layout were sampled from supplied previews; exact fonts, spacing, assets and states have not been measured from Figma layers |
| Auto Layout and responsive layouts | Implemented and partly verified | Storyboard/XIB constraints, width-aware grid sizing, iPhone/iPad UI tests; all rotation/window sizes not exhaustively checked |
| Dynamic Type | Implemented and partly verified | UIFontMetrics, expanding cells, accessibility single column and maximum-text-size UI test; list heading corrected to a scaled font during this audit |
| Liquid Glass and iOS 18–25 fallback | Implemented | iOS 26 availability-gated prominentGlass button configuration, filled fallback; visual polish on iOS 26 remains a manual check |
| iPad side-by-side list/detail | Implemented and tested | UISplitViewController; compact navigation and iPad UI tests |
| Pull refresh and full article in Safari | Implemented | UIRefreshControl and SFSafariViewController; complete Safari interaction remains a manual acceptance check |
| Bonus transitions and states | Implemented | Custom push transition with Reduce Motion guard; hosted loading, empty, offline and error states |
| Exact API with Alamofire | Implemented and verified | Required mocki endpoint, HTTP status validation, timeouts; normal launch decoded 79 articles |
| Requests/responses/errors logged using XCGLogger | Implemented | Request URL, status/byte count, decoded count and errors; release warning/error level |
| Swinject dependencies; controllers use managers | Implemented | AppDelegate composition root injects managers into storyboard controllers; provider protocol boundary |
| Persistent Cache and failure/offline fallback | Implemented and tested | Actor-isolated Cache storage, persisted snapshot test, offline/server failure manager tests, cache read/write error handling |
| Reachability, offline message, reconnect refresh | Implemented; integration validation partial | Reachability notifier → manager callback → list refresh; callback forwarding tested, real radio reconnection not manually verified |
| Kingfisher placeholders and image fallback | Implemented | Shared image view, cancellation on reuse, retry and retained missing/failure placeholder; real image loading observed |
| Missing/null/wrong-type fields and invalid links | Implemented and tested | Tolerant Codable decoding, readable fallbacks, URL validation, disabled invalid-link actions |
| Invalid JSON without crashing or erasing cache | Implemented and tested | Decoder throws controlled error; manager falls back to snapshot; malformed entries skipped |
| Required project structure and single responsibility | Implemented | Required directories present; optional Externals omitted because dependencies are unmodified pods; router, decoder, cache, connectivity and UI presentation separated |
| Code quality and absence of warnings | Partial | Fresh build passed without observed Swift compiler warnings; Xcode emitted AppIntents metadata extraction warnings, so zero total build warnings is not claimed |
| Public repository, incremental commits and README | Implemented | Public GitHub source, descriptive incremental history, locked setup, assumptions, improvements and documented validation limits |
| Ease of running | Verified locally | Fresh simulator build/install/launch passed; Scripts/run.sh replaces the installed app without deleting saved data |

## Submission judgment

The functional and architectural requirements are substantially implemented. Do not claim full compliance or pixel-perfect completion until Figma measurements and visual comparison are completed. Finish the manual acceptance steps in VALIDATION.md for real offline/reconnection, Safari, accessibility, iPad resizing and iOS 26 appearance. The earlier 36-test pass predates this audit's small heading-font correction; the correction receives a fresh build check separately.
