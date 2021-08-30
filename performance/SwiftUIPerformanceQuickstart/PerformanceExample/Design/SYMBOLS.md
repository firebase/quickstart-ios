# Performance Monitoring Quickstart SwiftUI Symbols

## Table of Contents
- [PerformanceExampleApp](#performanceexampleapp)
    - [init](#init)
    - [body](#body)
- [Process](#process)
    - [status](#status)
    - [image](#image)
    - [saliencyMap](#saliencymap)
    - [uploadSucceeded](#uploadsucceeded)
    - [categories](#categories)
    - [context](#context)
    - [isRunning](#isrunning)
    - [precision](#precision)
    - [site](#site)
    - [updateStatusAsync](#updatestatusasync)
    - [updateImageAsync](#updateimageasync)
    - [updateSaliencyMapAsync](#updatesaliencymapasync)
    - [downloadImageAsync](#downloadimageasync)
    - [classifyImageAsync](#classifyimageasync)
    - [generateSaliencyMapAsync](#generatesaliencymapasync)
    - [uploadSaliencyMapAsync](#uploadsaliencymapasync)
    - [updateStatus](#updatestatus)
    - [updateImage](#updateimage)
    - [updateSaliencyMap](#updatesaliencymap)
    - [downloadImage](#downloadimage)
    - [classifyImage](#classifyimage)
    - [generateSaliencyMap](#generatesaliencymap)
    - [uploadSaliencyMap](#uploadsaliencymap)
    - [makeTrace](#maketrace)
- [ProcessDerivatives](#processderivatives)
    - [ProcessTask](#processtask)
    - [ProcessStatus](#processstatus)
        - [text](#text)
        - [view](#view)
- [MainView](#mainview)
    - [process](#process-1)
    - [body](#body-1)
- [DownloadView](#downloadview)
    - [process](#process-2)
    - [body](#body-2)
- [ClassifyView](#classifyview)
    - [process](#process-3)
    - [body](#body-3)
- [SaliencyMapView](#saliencymapview)
    - [process](#process-4)
    - [body](#body-4)
- [UploadView](#uploadview)
    - [process](#process-5)
    - [body](#body-5)

## `PerformanceExampleApp`
```swift
@main
struct PerformanceExampleApp: App
```
main point of entry into app

### `init`
```swift
init()
```
configures the FirebaseApp

### `body`
```swift
var body: some Scene
```
returns a WindowGroup containing a MainView

## `Process`
```swift
class Process: ObservableObject
```
handles requests for running different processes

### `status`
```swift
@Published var status: ProcessStatus
```
publishes the status of the current process

### `image`
```swift
@Published var image: UIImage?
```
stores the downloaded image

### `saliencyMap`
```swift
@Published var saliencyMap: UIImage?
```
stores the generated saliency map

### `uploadSucceeded`
```swift
var uploadSucceeded : Bool
```
indicates the status of the upload task

### `categories`
```swift
var categories: [(category: String, confidence: VNConfidence)]?
```
stores the results of the classification task

### `context`
```swift
lazy var context: CIContext { get set }
```
stores the CIContext used to generate the saliency map, initializing it when it needs to

### `isRunning`
```swift
var isRunning: Bool { get }
```
returns whether a process is currently running

### `precision`
```swift
let precision: Float
```
stores the precision used for the classification task

### `site`
```swift
let site : String
```
stores the site from which to download the image

### `updateStatusAsync`
```swift
@MainActor @available(iOS 15, tvOS 15,*)
func updateStatusAsync(to newStatus: ProcessStatus, updateUploadStatus: Bool = false)
```
updates the Process status asynchronously, possibly updating the status of the upload task

### `updateImageAsync`
```swift
@MainActor @available(iOS 15, tvOS 15, *)
func updateImageAsync(to newImage: UIImage?)
```
updates the Process image asynchronously

### `updateSaliencyMapAsync`
```swift
@MainActor @available(iOS 15, tvOS 15, *)
func updateSaliencyMapAsync(to newSaliencyMap: UIImage?)
```
updates the Process saliency map asynchronously

### `downloadImageAsync`
```swift
@available(iOS 15, tvOS 15, *)
func downloadImageAsync() async
```
attempts to download the image from the Process site asynchronously and set it as the new Process 
image, updating the Process status accordingly

### `classifyImageAsync`
```swift
@available(iOS 15, tvOS 15, *)
func classifyImageAsync() async
```
attempts to classify the Process image asynchronously and update the Process categories with the 
results, measuring the classification task with a custom code trace and updating the Process status
 accordingly

### `generateSaliencyMapAsync`
```swift
@available(iOS 15, tvOS 15, *)
func generateSaliencyMapAsync() async
```
attempts to generate the Process saliency map asynchronously, measuring the task with a custom code
 trace and updating the Process status accordingly

### `uploadSaliencyMapAsync`
```swift
@available(iOS 15, tvOS 15, *)
func uploadSaliencyMapAsync(compressionQuality: CGFloat = 0.5) async
```
attempts to upload the Process saliency map asynchronously as `saliency_map.jpg` using 
compressionQuality, updating the Process status accordingly

### `updateStatus`
```swift
func updateStatus(to newStatus: ProcessStatus, updateUploadStatus: Bool = false)
```
updates the Process status on the main thread, possibly updating the status of the upload task

### `updateImage`
```swift
func updateImage(to newImage: UIImage?)
```
updates the Process image on the main thread

### `updateSaliencyMap`
```swift
func updateSaliencyMap(to newSaliencyMap: UIImage?)
```
updates the Process saliency map on the main thread

### `downloadImage`
```swift
func downloadImage()
```
attempts to download the image from the Process site and set it as the new Process image, updating 
the Process status accordingly

### `classifyImage`
```swift
func classifyImage()
```
attempts to classify the Process image and update the Process categories with the results, 
measuring the classification task with a custom code trace and updating the Process status 
accordingly

### `generateSaliencyMap`
```swift
​​func generateSaliencyMap()
```
attempts to generate the Process saliency map, measuring the task with a custom code trace and 
updating the Process status accordingly

### `uploadSaliencyMap`
```swift
func uploadSaliencyMap(compressionQuality: CGFloat = 0.5)
```
attempts to upload the Process saliency map as 'saliency_map.jpg’ using compressionQuality, 
updating the Process status accordingly

### `makeTrace`
```swift
func makeTrace(called name: String) -> Trace?
```
attempts to create and return a trace, setting its custom attributes of “precision” to the Process 
precision and “platform” to one of “iOS” or “tvOS”

## ProcessDerivatives

### `ProcessTask`
```swift
enum ProcessTask: String {
  case download = "Download"
  case classify = "Classification"
  case saliencyMap = "Saliency Map"
  case upload = "Upload"
}
```
tracks the different process tasks

### `ProcessStatus`
```swift
enum ProcessStatus: Equatable {
  case idle
  case running(ProcessTask)
  case failure(ProcessTask)
  case success(ProcessTask)
    .
    .
    .
}
```
tracks the different states of a process

#### `text`
```swift
var text: String { get }
```
returns String representation of status

#### `view`
```swift
var view: some View
```
returns the corresponding `View` wrapped by `HStack`

## `MainView`
```swift
struct MainView: View
```
main menu

### `process`
```swift
@StateObject var process = Process()
```
initializes a new Process to handle the image tasks

### `body`
```swift
var body: some View { get }
```
returns the MainView process status on top of a list of links to each of the image task Views 
(DownloadView, ClassifyView, SaliencyMapView, or UploadView) passing in the MainView process, with 
a navigation title of “Performance”

## `DownloadView`
```swift
struct DownloadView: View
```
view for download task

### `process`
```swift
@ObservedObject var process: Process
```
stores the MainView process

### `body`
```swift
var body: some View { get }
```
returns the downloaded process image with a confirmation message, otherwise returns a placeholder 
image with a message asking the user to download the image using the download button, with the 
process status shown on top

## `ClassifyView`
```swift
struct ClassifyView: View
```
view for classification task

### `process`
```swift
@ObservedObject var process: Process
```
stores the MainView process

### `body`
```swift
var body: some View { get }
```
returns the classified process image with the list of categories found (if any) and a corresponding
 message, otherwise returns the downloaded process image and a button to classify the image, 
 otherwise returns a placeholder image with a message asking the user to download the image, with 
 the process status shown on top

## `SaliencyMapView`
```swift
struct SaliencyMapView: View
```
view for saliency map task

### `process`
```swift
@ObservedObject var process: Process
```
stores the MainView process

### `body`
```swift
var body: some View { get }
```
returns the generated saliency map process image with a confirmation message, otherwise returns the
 downloaded process image and a button to generate the saliency map, otherwise returns a 
 placeholder image with a message asking the user to download the image, with the process status 
 shown on top

## `UploadView`
```swift
struct UploadView: View
```
view for upload task

### `process`
```swift
@ObservedObject var process: Process
```
stores the MainView process

### `body`
```swift
var body: some View { get }
```
returns the uploaded saliency map with a confirmation message, otherwise returns the generated 
saliency map and a button to upload it, otherwise returns a placeholder image with a message asking
 the user to download the image and to generate the saliency map, with the process status shown on 
 the toolbar