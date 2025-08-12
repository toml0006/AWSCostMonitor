fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Mac

### mac setup

```sh
[bundle exec] fastlane mac setup
```

Setup Fastlane for first time use

### mac test

```sh
[bundle exec] fastlane mac test
```

Run tests

### mac build_debug

```sh
[bundle exec] fastlane mac build_debug
```

Build a debug version

### mac screenshots

```sh
[bundle exec] fastlane mac screenshots
```

Generate new App Store screenshots

### mac upload_screenshots

```sh
[bundle exec] fastlane mac upload_screenshots
```

Upload screenshots to App Store Connect

### mac bump_version

```sh
[bundle exec] fastlane mac bump_version
```

Bump version number

### mac create_app

```sh
[bundle exec] fastlane mac create_app
```

Instructions for creating app on App Store Connect

### mac upload_metadata

```sh
[bundle exec] fastlane mac upload_metadata
```

Upload metadata to App Store Connect

### mac release

```sh
[bundle exec] fastlane mac release
```

Build and upload to App Store Connect

### mac submit_for_review

```sh
[bundle exec] fastlane mac submit_for_review
```

Submit app for review

### mac create_iap

```sh
[bundle exec] fastlane mac create_iap
```

Create In-App Purchase on App Store Connect

### mac beta

```sh
[bundle exec] fastlane mac beta
```

Build app for manual App Store upload

### mac download_metadata

```sh
[bundle exec] fastlane mac download_metadata
```

Download metadata from App Store Connect

### mac validate

```sh
[bundle exec] fastlane mac validate
```

Validate app before submission

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
