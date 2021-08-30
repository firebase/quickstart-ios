# A/B Testing Quickstart SwiftUI Design

## Table of Contents
- [Context](#context)
- [Design](#design)
    - [AppConfig](#appconfig)
    - [Swift 5.5 & iOS 15](#swift-55--ios-15)

## Context
This document presents the design for the SwiftUI version of the 
[Firebase A/B Testing Quickstart](..), an iOS app that demonstrates the use of 
[Firebase A/B Testing](https://firebase.google.com/products/ab-testing). This SwiftUI version of 
the Quickstart is meant to show use of Firebase products (A/B Testing, 
[Remote Config](#further-reading), [Installations](#further-reading)) alongside the latest Apple 
technologies ([SwiftUI](https://developer.apple.com/documentation/SwiftUI), 
[async / await](#swift-55--ios-15), [Swift Package Manager](https://swift.org/package-manager)) 
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

### Swift 5.5 & iOS 15
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