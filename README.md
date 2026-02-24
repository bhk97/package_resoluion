# fdr — Flutter Dependency Resolver

A CLI tool that checks for version conflicts across `pubspec.yaml`, Gradle, and CocoaPods before you add a new package to your Flutter project.

## The Problem

Adding a package to a Flutter project can break the build due to mismatched versions — not just in pubspec, but also in Gradle (compileSdk, AGP, Kotlin) and iOS (deployment target). You end up fixing one error only to hit the next, often spending hours on StackOverflow.

`fdr` scans all three layers at once, shows every conflict upfront, and tells you exactly what to change and where.

## What It Checks

| Layer | What |
|---|---|
| **Dart** | SDK constraints, dependency version clashes, transitive conflicts |
| **Android** | compileSdk, minSdk, AGP, Kotlin, Gradle, JDK compatibility chain |
| **iOS** | Deployment target, framework linking |

## Installation

```bash
dart pub global activate --source path ./fdr
```

Or run directly from the project:

```bash
cd fdr
dart pub get
```

## Usage

```bash
# Check what happens when you add a package
dart run bin/fdr.dart --add firebase_auth --path /path/to/your/project

# Check a specific version
dart run bin/fdr.dart --add camera --version ^0.10.0

# Just scan project health (no package to add)
dart run bin/fdr.dart --scan-only --path /path/to/your/project

# JSON output (for CI or scripts)
dart run bin/fdr.dart --add firebase_auth --json
```

## Options

```
-p, --path         Path to Flutter project (default: current dir)
-a, --add          Package to check
-v, --version      Specific version constraint (default: latest)
    --scan-only    Scan project without adding a package
    --json         Output as JSON
    --verbose      Show debug info
-h, --help         Show help
```

## Example Output

```
$ fdr --path ./my_app --add firebase_auth

SCANNING PROJECT...
  pubspec.yaml        (12 deps, 4 dev_deps)
  android/build.gradle (AGP 7.4.2, Kotlin 1.7.10)
  ios/Podfile          (platform :ios, '11.0')

4 CONFLICTS DETECTED

CONFLICT 1 [DART]
  firebase_auth needs firebase_core ^4.4.0
  Your project has firebase_core ^2.24.0
  FIX: Update firebase_core to ^4.4.0 in pubspec.yaml

CONFLICT 2 [ANDROID]
  compileSdk 33 too low, needs 34
  Also requires AGP 8.1+ (you have 7.4.2) and Gradle 8.0+ (you have 7.5)

CONFLICT 3 [ANDROID]
  Kotlin 1.7.10 too old, needs 1.8.0+

CONFLICT 4 [iOS]
  Deployment target 11.0 too low, needs 13.0

RECOMMENDED VERSION COMBO
  compileSdk  33 → 34
  AGP         7.4.2 → 8.1+
  Gradle      7.5 → 8.0+
  Kotlin      1.7.10 → 1.9.22
  iOS target  11.0 → 13.0
```

## How It Works

1. Scans your project files (pubspec.yaml, pubspec.lock, Gradle files, Podfile)
2. Fetches the package info from pub.dev API
3. Runs conflict checks across Dart, Android, and iOS layers
4. Outputs all conflicts with exact file paths and fix values

## Project Structure

```
fdr/
├── bin/fdr.dart                    # Entry point
├── lib/src/
│   ├── cli/runner.dart             # Argument parsing
│   ├── scanner/                    # File parsers (pubspec, gradle, podfile)
│   ├── fetcher/pub_api_client.dart # pub.dev API client
│   ├── engine/                     # Conflict detection logic
│   ├── models/                     # Data classes
│   └── reporter/                   # Terminal and JSON output
└── pubspec.yaml
```

## License

MIT
