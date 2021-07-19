Firebase Crashlytics Quickstart
=============================

The Firebase Crashlytics iOS quickstart demonstrates how to report crashes and log events leading up
to those crashes. You can read more about Firebase Crashlytics
[here](https://firebase.google.com/docs/crashlytics/)! 

To view the older Objective-C and Swift quickstarts, view the
[`LegacyCrashlyticsQuickstart`](https://github.com/firebase/quickstart-ios/tree/master/crashlytics/LegacyCrashlyticsQuickstart)
directory.

Getting Started
---------------

### Clone and open Crashlytics quickstart project

- Clone the quickstart repo and `cd` into the `crashlytics` directory
- Open file `CrashlyticsExample.xcodeproj` project using Xcode.

```bash
$ git clone https://github.com/firebase/quickstart-ios.git
$ cd crashlytics/
$ open CrashlyticsExample.xcodeproj
```

### Connecting to the Firebase Console 
- To have a functional application, you will need to connect the Crashlytics quickstart example with
  the [Firebase Console](https://console.firebase.google.com).
- For an in depth explanation, you can read more about [adding Firebase to your iOS
  Project](https://firebase.google.com/docs/ios/setup). Below is a summary of the main steps:
  1. Visit the [Firebase Console](https://console.firebase.google.com) 
  2. Add an iOS app to the project. Make sure the `Bundle Identifier` you set for this iOS App
     matches that of the one in this quickstart.
  3. Download the `GoogleService-Info.plist` when prompted.
  4. Drag the downloaded `GoogleService-Info.plist` into the opened quickstart app under the
     `Shared` folder.
- Now you should be able to build and run the Firebase project!

### Trigger a crash in Crashlytics quickstart app
1. Click `Build and then run the current scheme` in Xcode to build your app on a device or
   simulator.
2. Click `Stop running the scheme or action` in Xcode to close the initial instance of your app.
   This initial instance includes a debugger that interferes with Crashlytics.
3. Open your app again from the simulator or device.
4. Touch `Crash` button to crash the app.
5. Open your app once more to let the Crashlytics API report the crash. Your crash should show up in
   the [Firebase Console](https://console.firebase.google.com) within 5 minutes.

For details on how to test out Crashlytics, read [Test your Crashlytics
implementation](https://firebase.google.com/docs/crashlytics/test-implementation?hl=hu&platform=ios)

Support
-------

- [Firebase Support](https://firebase.google.com/support/)

License
-------

Copyright 2021 Google, Inc.

Licensed to the Apache Software Foundation (ASF) under one or more contributor
license agreements.  See the NOTICE file distributed with this work for
additional information regarding copyright ownership.  The ASF licenses this
file to you under the Apache License, Version 2.0 (the "License"); you may not
use this file except in compliance with the License.  You may obtain a copy of
the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
License for the specific language governing permissions and limitations under
the License.
