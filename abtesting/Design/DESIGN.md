# A/B Testing Quickstart SwiftUI Design

## Table of Contents
- [Context](#context)
- [Design](#design)
    - [AppConfig](#appconfig)
    - [Multi-platform](#multi-platform)
    - [Conditional Compilation](#conditional-compilation)

## Context
This document presents the design for the SwiftUI version of the 
[Firebase A/B Testing Quickstart](..), an iOS app that demonstrates the use of 
[Firebase A/B Testing](https://firebase.google.com/products/ab-testing). This SwiftUI version of 
the Quickstart is meant to show use of Firebase products (A/B Testing, 
[Remote Config](#further-reading), [Installations](#further-reading)) alongside the latest Apple 
technologies ([SwiftUI](https://developer.apple.com/documentation/SwiftUI), 
[Swift Concurrency](#conditional-compilation), [Swift Package Manager](https://swift.org/package-manager)) 
developers might want to use.

## Design
The app demonstrates using an A/B Testing experiment to test multiple color schemes within an app, 
which consists of a static list of Firebase products with a refresh button at the bottom of the 
screen and pull-to-refresh functionality on iOS 15.

The typical usage flow consists of [setting up the A/B Testing experiment](../README.md) in the 
Firebase Console, enrolling the test device in the experiment, launching the app, moving the test 
device into / out of the experiment, and refreshing using the button or, if available, the 
pull-to-refresh functionality.

### [`AppConfig`](SYMBOLS.md#appconfig-1)
To handle app state and communication with RemoteConfig, the class 
[`AppConfig`](SYMBOLS.md#appconfig-1) provides the main logic for reacting to changes to the 
installation auth token, fetching the color scheme from RemoteConfig, and updating the UI with any 
changes while also handling error management.

### Multi-platform
This Quickstart supports the iOS, tvOS, macOS, watchOS, and Mac Catalyst platforms. Thanks to 
[SwiftUI](https://developer.apple.com/documentation/SwiftUI), all code can be shared across the 
platforms; the only code difference between the platforms is very intentional: the withholding of 
`NavigationView` on macOS and the absence of Firebase Installations on Mac Catalyst. [Swift Package 
Manager](https://swift.org/package-manager/) makes the integration of Firebase products more 
streamlined and aligned with up-and-coming best practices for third-party libraries.

### Conditional Compilation
The app contains a conditional compilation block which checks for the availability of Swift 5.5 and
 houses an availability condition which checks for the availability of iOS 15. This allows the app 
 to showcase the latest Apple technologies such as [Swift Concurrency
 ](https://developer.apple.com/documentation/swift/swift_standard_library/concurrency) like async /
  await, Tasks, and MainActor while also being backward compatible with iOS 14 or when compiled 
  with earlier versions of Swift.

### Further Reading
- [Learn more about Firebase A/B Testing](https://firebase.google.com/docs/ab-testing)
- [Learn more about Firebase Remote Config](https://firebase.google.com/docs/remote-config)
- [Learn more about Firebase Installations](https://firebase.google.com/docs/projects/manage-installations)