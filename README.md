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
Download the generated `GoogleService-Info.plist` file, and copy it to the root
directory of the sample you wish to run.

- [A/B Testing](abtesting/README.md)
- [Admob](admob/README.md)
- [Analytics](analytics/README.md)
- [Authentication](authentication/README.md)
- [Config](config/README.md)
- [Crashlytics](crashlytics/README.md)
- [Database](database/README.md)
- [Firestore](firestore/README.md)
- [Functions](functions/README.md)
- [Dynamic Links](dynamiclinks/README.md)
- [Cloud Messaging](messaging/README.md)
- [Performance](performance/README.md)
- [Storage](storage/README.md)

## How to make contributions?
Please read and follow the steps in the [CONTRIBUTING.md](CONTRIBUTING.md)

## License
See [LICENSE](LICENSE)

[![Build Status](https://travis-ci.org/firebase/quickstart-ios.svg?branch=master)](https://travis-ci.org/firebase/quickstart-ios)
