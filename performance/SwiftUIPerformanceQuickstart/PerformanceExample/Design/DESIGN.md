# Performance Monitoring Quickstart SwiftUI Design

## Table of Contents
- [Context](#context)
- [Design](#design)
    - [Image Application](#image-application)
    - [Process / Process Derivatives](#process--process-derivatives)
    - [Vision](#vision)
    - [FirebaseStorage / FirebaseStorageSwift](#firebasestorage--firebasestorageswift)
    - [Multi-platform](#multi-platform)
    - [Conditional Compilation](#conditional-compilation)

# Context
This document presents the design for the SwiftUI version of the [Firebase Performance Monitoring 
Quickstart](..), an iOS / tvOS app that demonstrates the use of 
[Firebase Performance Monitoring](https://firebase.google.com/products/performance). This SwiftUI 
version of the Quickstart is meant to show use of Firebase products (Performance Monitoring and 
[Storage](https://firebase.google.com/products/storage)) alongside the latest Apple technologies 
([SwiftUI](#multi-platform), [shared cross-platform code](#multi-platform), 
[async / await](#conditional-compilation), [Swift Package Manager](#multi-platform), [Vision](#vision)) 
developers might want to use.

# Design

## Image Application
The app is centered around image tasks: download, classify, saliency map, and upload. Downloading 
and uploading images is a common developer task. Classifying images and generating saliency maps 
are tasks that might be more popular now with the success of computer vision algorithms. 
[Classifying an image](#further-reading) consists of providing categories to which the image 
belongs. A [saliency map](#further-reading) identifies the parts of an image most likely to draw 
attention.

Network requests are [automatically traced](#further-reading) by Performance Monitoring, while 
[custom traces](#further-reading) are used to measure the computer vision tasks while 
[tracking custom attributes](#further-reading) such as classification precision and platform type.

The typical usage flow consists of downloading the image, classifying the image, generating the 
saliency map, and lastly uploading the saliency map. The status of the task (idle, running, 
success, failure) is displayed for the end-user’s convenience.

To simulate long-running processes, these image tasks were preferred over sorting a large array of 
random numbers, sleep operations, or more complex tasks like Fourier Transforms because they better
 represent common tasks developers might include in their applications even if the other proposed 
 solutions would actually be processes that run for longer.

## [`Process`](SYMBOLS.md#process) / [`Process Derivatives`](SYMBOLS.md#processderivatives)
To handle the image tasks, a class `Process` and associated enums 
[`ProcessStatus`](SYMBOLS.md#processstatus) and [`ProcessTask`](SYMBOLS.md#processtask) provide the
 main logic for performing the various image tasks when available and reporting the status for each
  one back to the UI while also handling error management.

Although breaking up `Process` into smaller classes for each task would likely make it easier to 
maintain and extend the Quickstart in the future, no new processes will be added once the rewrite 
is complete so those trade-offs are worth making to keep a single unifying class.

## Vision
[Apple's Vision framework](#further-reading) is used to perform the image classification and 
saliency map generation tasks. It allows for the execution of such tasks solely with on-device 
computation with no extra overhead other than importing the framework. 
[Classification](#further-reading) and [saliency maps](#further-reading) were deemed simpler and 
more common use cases of the Vision framework when compared with other available tasks like body 
and hand pose detection.

Although use of [Firebase Machine Learning](https://firebase.google.com/products/ml) would align 
with the goal of showcasing Firebase products, this was not pursued in light of the need to 
download TensorFlow Lite models to run the algorithms on-device but primarily because of the other 
goal of showcasing Firebase use alongside the latest Apple technology developers might want to 
use, which includes the Vision framework. This also keeps the number of third-party dependencies 
small, which is important given that the Quickstart is meant as a simple introduction for 
developers.
## FirebaseStorage / FirebaseStorageSwift
To measure upload network requests, [Storage](#further-reading) was used to host the uploaded 
image, further demonstrating Firebase use while not relying on some other third party service. At 
the same time, Storage provides 
[FirebaseStorageSwift](https://firebase.google.com/docs/ios/learn-more#swift_extensions), which 
[exposes
](https://github.com/firebase/firebase-ios-sdk/blob/main/FirebaseStorageSwift/CHANGELOG.md) the 
[Result](https://developer.apple.com/documentation/swift/result) type for [better handling of 
asynchronous code
](https://developer.apple.com/documentation/swift/result/writing_failable_asynchronous_apis) such 
as that used for Storage upload completion handlers.
## Multi-platform
This Quickstart supports both iOS and tvOS platforms. Thanks to 
[SwiftUI](https://developer.apple.com/documentation/SwiftUI), all code can be shared across the two
 platforms; the only code difference between the two platforms is very intentional: the value 
 passed to the custom attribute `platform` indicates which of the two platforms is running the 
 application. [Swift Package Manager](https://swift.org/package-manager) makes the integration of 
 Firebase products more streamlined and aligned with up-and-coming best practices for third-party 
 libraries.
## Conditional Compilation
Scattered throughout the application are conditional compilation blocks which check for the 
availability of Swift 5.5 and house availability conditions which check for the availability of iOS
 15 or tvOS 15. These allow the application to showcase the latest Apple technologies such as 
 [Swift Concurrency
 ](https://developer.apple.com/documentation/swift/swift_standard_library/concurrency) with async /
  await, Tasks, and MainActor while also being backward compatible with iOS 14 and tvOS 14 or when 
  compiled with earlier versions of Swift.
### Further Reading
- [Read more about Firebase Performance Monitoring](https://firebase.google.com/docs/perf-mon)
- [Read more about Firebase Storage](https://firebase.google.com/docs/storage)
- [Read more about Apple's Vision framework](https://developer.apple.com/documentation/vision)
  - [See sample code for classifying images](https://developer.apple.com/documentation/vision/classifying_images_for_categorization_and_search)
  - [See sample code for saliency maps](https://developer.apple.com/documentation/vision/highlighting_areas_of_interest_in_an_image_using_saliency)