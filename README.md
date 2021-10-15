# Firebase Quickstarts for iOS

A collection of quickstart samples demonstrating the Firebase APIs on iOS. Each sample contains targets
for both Objective-C and Swift. For more information, see https://firebase.google.com.

## Samples

You can open each of the following samples as an Xcode project, and run
them on a mobile device or a simulator. Simply install the pods and open
the .xcworkspace file to see the project in Xcode.
```
$ pod install --repo-update
$ open your-project.xcworkspace
```
When doing so you need to add each sample app you wish to try to a Firebase
project on the [Firebase console](https://console.firebase.google.com).
You can add multiple sample apps to the same Firebase project.
There's no need to create separate projects for each app.

To add a sample app to a Firebase project, use the bundleID from the Xcode project.
Download the generated `GoogleService-Info.plist` file, and replace the existing plist
to the root directory of the sample you wish to run.

### Code Formatting

To ensure that the code is formatted consistently, run the script
[./scripts/style.sh](https://github.com/firebase/quickstart-ios/blob/master/scripts/style.sh)
before creating a PR.

GitHub Actions will verify that any code changes are done in a style compliant
way. Install `mint` and `swiftformat`:

```console
brew install mint
mint bootstrap
./scripts/style.sh
```

- [A/B Testing](abtesting/README.md) ![build](https://github.com/firebase/quickstart-ios/actions/workflows/abtesting.yml/badge.svg)
- [Admob](admob/README.md) ![build](https://github.com/firebase/quickstart-ios/actions/workflows/admob.yml/badge.svg)
- [Analytics](analytics/README.md) ![build](https://github.com/firebase/quickstart-ios/actions/workflows/analytics.yml/badge.svg)
- [Authentication](authentication/README.md) ![build](https://github.com/firebase/quickstart-ios/actions/workflows/authentication.yml/badge.svg)
- [Remote Config](config/README.md) ![build](https://github.com/firebase/quickstart-ios/actions/workflows/config.yml/badge.svg)
- [Crashlytics](crashlytics/README.md) ![build](https://github.com/firebase/quickstart-ios/actions/workflows/crashlytics.yml/badge.svg)
- [Database](database/README.md) ![build](https://github.com/firebase/quickstart-ios/actions/workflows/database.yml/badge.svg)
- [Firestore](firestore/README.md) ![build](https://github.com/firebase/quickstart-ios/actions/workflows/firestore.yml/badge.svg)
- [Functions](functions/README.md) ![build](https://github.com/firebase/quickstart-ios/actions/workflows/functions.yml/badge.svg)
- [Dynamic Links](dynamiclinks/README.md) ![build](https://github.com/firebase/quickstart-ios/actions/workflows/dynamiclinks.yml/badge.svg)
- [Cloud Messaging](messaging/README.md) ![build](https://github.com/firebase/quickstart-ios/actions/workflows/messaging.yml/badge.svg)
- [Performance](performance/README.md) ![build](https://github.com/firebase/quickstart-ios/actions/workflows/performance.yml/badge.svg)
- [Storage](storage/README.md) ![build](https://github.com/firebase/quickstart-ios/actions/workflows/storage.yml/badge.svg)

## How to make contributions?
Please read and follow the steps in the [CONTRIBUTING.md](CONTRIBUTING.md)

## License
See [LICENSE](LICENSE)
