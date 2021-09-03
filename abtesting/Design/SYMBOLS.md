# A/B Testing Quickstart SwiftUI Symbols

## Table of Contents
- [ABTestingExampleApp](#abtestingexampleapp)
    - [appConfig](#appconfig)
    - [init](#init)
    - [body](#body)
- [AppConfig](#appconfig-1)
    - [AppConfig](#appconfig-2)
        - [colorScheme](#colorscheme)
        - [init](#init-1)
        - [deinit](#deinit)
        - [updateFromRemoteConfig](#updatefromremoteconfig)
        - [updateFromRemoteConfigAsync](#updatefromremoteconfigasync)
        - [printInstallationAuthToken](#printinstallationauthtoken)
    - [ColorScheme](#colorscheme-1)
        - [init](#init-2)
    - [RemoteConfigFetchAndActivateStatus](#remoteconfigfetchandactivatestatus)
        - [debugDescription](#debugdescription)
- [ContentView](#contentview)
    - [ContentView](#contentview-1)
        - [appConfig](#appconfig-3)
        - [body](#body-1)
    - [FirebaseList](#firebaselist)
        - [appConfig](#appconfig-4)
        - [data](#data)
        - [body](#body-2)
    - [BasicList](#basiclist)
        - [data](#data-1)
        - [body](#body-3)

## `ABTestingExampleApp`
```swift
@main
struct ABTestingExampleApp: App
```
main point of entry into app

### `appConfig`
```swift
var appConfig: AppConfig
```
stores the AppConfig instance

### `init`
```swift
init()
```
configures the FirebaseApp, configures RemoteConfig, and initializes AppConfig instance

### `body`
```swift
var body: some Scene
```
returns a `WindowGroup` containing a `ContentView` with appConfig passed in

## AppConfig

### `AppConfig`
```swift
class AppConfig: ObservableObject
```
handles communication with RemoteConfig and updating the UI

#### `colorScheme`
```swift
@Published var colorScheme: ColorScheme
```
stores the color scheme for the app

#### `init`
```swift
init()
```
updates app's color scheme from RemoteConfig and adds observer to print installation auth token if 
it changes on platforms other than Mac Catalyst

#### `deinit`
```swift
deinit
```
removes installation auth token change observer on platforms other than Mac Catalyst

#### `updateFromRemoteConfig`
```swift
func updateFromRemoteConfig()
```
retrieves color scheme from RemoteConfig and updates app's color scheme on the main thread if it 
has changed

#### `updateFromRemoteConfigAsync`
```swift
@available(iOS 15, tvOS 15, macOS 12, watchOS 8, *)
func updateFromRemoteConfigAsync() async
```
retrieves color scheme from RemoteConfig asynchronously and updates app's color scheme on the main 
thread if it has changed

#### `printInstallationAuthToken`
```swift
@objc func printInstallationAuthToken()
```
prints installation auth token on platforms other than Mac Catalyst 

### `ColorScheme`
```swift
extension ColorScheme
```
extends ColorScheme to deal with String initializer

#### `init`
```swift
init(_ value: String)
```
returns the corresponding ColorScheme, defaulting to light otherwise

### `RemoteConfigFetchAndActivateStatus`
```swift
extension RemoteConfigFetchAndActivateStatus
```
extends RemoteConfigFetchAndActivateStatus with debug description

#### `debugDescription`
```swift
var debugDescription: String { get }
```
prints String representation of status

## ContentView

### `ContentView`
```swift
struct ContentView: View
```
main content view

#### `appConfig`
```swift
@ObservedObject var appConfig: AppConfig
```
stores app's AppConfig instance

#### `body`
```swift
var body: some View { get }
```
returns a `FirebaseList` wrapped with `NavigationView` when not on macOS

### `FirebaseList`
```swift
struct FirebaseList: View
```
multi-platform view for a `BasicList` populated with Firebase data

#### `appConfig`
```swift
@ObservedObject var appConfig: AppConfig
```
stores app's AppConfig instance

#### `data`
```swift
let data: [(title: String, subtitle: String)]
```
stores array of title-subtitle String pairings specific to Firebase

#### `body`
```swift
var body: some View { get }
```
returns `VStack` containing a `BasicList` populated with the Firebase data on top of a "Refresh" 
`Button`, which updates appConfig's color scheme from Remote Config and is done asynchronously if 
refreshed by pulling down on the list on iOS 15, with a navigation title of "Firenotes", preferred 
color scheme of appConfig's color scheme, and foreground color corresponding to appConfig's color 
scheme (orange for dark color scheme, primary for light color scheme)

### `BasicList`
```swift
struct BasicList: View
```
view for a basic list of title-subtitle String pairings

#### `data`
```swift
let data: [(title: String, subtitle: String)]
```
stores array of title-subtitle String pairings

#### `body`
```swift
var body: some View { get }
```
returns `List` of `VStacks` each containing a `Text` title on top of a `Text` subtitle derived from
 data
