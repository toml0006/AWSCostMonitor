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

### mac status

```sh
[bundle exec] fastlane mac status
```

Show App Store version states, attached build, and any open review submission

### mac submit

```sh
[bundle exec] fastlane mac submit
```

Submit an already-uploaded build for review. Usage: fastlane mac submit version:1.7.0 build:109

### mac notes

```sh
[bundle exec] fastlane mac notes
```

Push release notes / metadata for a version without submitting. Usage: fastlane mac notes version:1.7.0

### mac pull_metadata

```sh
[bundle exec] fastlane mac pull_metadata
```

Download current App Store metadata into fastlane/metadata for editing

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
