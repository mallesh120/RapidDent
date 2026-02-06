fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios build

```sh
[bundle exec] fastlane ios build
```

Build the app (debug, no code-sign)

### ios build_release

```sh
[bundle exec] fastlane ios build_release
```

Build for release (archive-ready)

### ios test

```sh
[bundle exec] fastlane ios test
```

Run unit tests

### ios ui_test

```sh
[bundle exec] fastlane ios ui_test
```

Run UI tests

### ios analyze

```sh
[bundle exec] fastlane ios analyze
```

Static analysis with xcodebuild analyze

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build & upload to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Build & submit to App Store for review

### ios clean

```sh
[bundle exec] fastlane ios clean
```

Clean derived data

### ios ci

```sh
[bundle exec] fastlane ios ci
```

Full CI pipeline: clean → build → test

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
