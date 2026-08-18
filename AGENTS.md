# AGENTS.md

## Project Overview

SwiftyUpdateKit is a Swift framework for iOS and macOS that provides App Store update
prompts, release notes, and review requests.

- Supported platforms: iOS 13.0 or later and macOS 10.15 or later
- Main implementation: `Framework/Sources/`
- Unit tests: `Framework/SwiftyUpdateKitTests/`
- Sample applications: `iOSSample/` and `MacSample/`
- Distribution binary: `Framework/SwiftyUpdateKit.xcframework/`
- Swift Package Manager manifest: `Package.swift`
- CocoaPods specification: `SwiftyUpdateKit.podspec`

## Implementation Guidelines

- Before making changes, inspect the target files and the related callers, callees, type
  definitions, tests, and configuration.
- Consider the impact on both iOS and macOS. Follow the existing `#if os(...)` patterns for
  platform-specific behavior.
- When changing a public API, check backward compatibility and update the README examples and API
  documentation as needed.
- When adding source or test files, add them to the appropriate target in
  `Framework/SwiftyUpdateKit.xcodeproj`.
- `Framework/SwiftyUpdateKit.xcframework/` is a generated distribution artifact. Do not edit it
  directly for source-only changes.
- When changing `Framework/PrivacyInfo.xcprivacy`, ensure that it remains consistent with the
  privacy manifests included in the distribution XCFramework for each platform.
- Do not include files under `ai-reviews/` in commits unless explicitly instructed to do so.

## Coding Conventions

- Format Swift code according to `.swiftformat`. The expected SwiftFormat version is defined in
  `codeformat.sh`.
- Follow the existing naming, access control, documentation comment, and closure styles.
- Keep code comments self-contained. When referring to an issue or external resource, summarize
  the reason and include the complete URL.
- When referring to another file in a comment, use a path relative to the repository root and do
  not depend on line numbers.

## Build and Test

The primary test command equivalent to CI is:

```sh
xcodebuild \
  -workspace SwiftyUpdateKit.xcworkspace \
  -scheme SwiftyUpdateKit \
  -destination 'platform=iOS Simulator,name=iPhone 12 Pro Max' \
  test
```

If the local environment does not have a simulator with that name, specify an available iOS
Simulator.

Install and run the code-formatting tools with:

```sh
npm run fmt:install
npm run fmt:fix
```

- Add or update tests in `Framework/SwiftyUpdateKitTests/` for each behavioral change.
- Keep tests independent of external services and test execution order.
- Depending on the scope of the change, verify the macOS target build in addition to the iOS
  tests.

## Documentation

- Update `README.md` when changing a public API or its usage.
- Use `make_docs.sh` to generate the API reference. Note that `.gitignore` excludes generated files
  under `docs/ios/` and `docs/macos/`, except for the badge files.
