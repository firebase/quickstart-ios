Firebase Database Quickstart
=============================

This Firebase quickstart showcases how Firebase Realtime Database (RTDB) can store and sync data.
Data is synced across all clients in realtime, and remains available when the app goes offline. You
can read more about Firebase Realtime Database [here](https://firebase.google.com/docs/database/)!

To view the SwiftUI quickstart, view the
[`DatabaseExampleSwiftUI/DatabaseExample`](https://github.com/firebase/quickstart-ios/tree/main/database/DatabaseExampleSwiftUI/DatabaseExample) 
directory.

Getting Started
---------------

### Clone and open Database quickstart project

- Clone the quickstart repo and `cd` into the `database/DatabaseExampleSwiftUI/DatabaseExample`
  directory.
- Open file `DatabaseExample.xcodeproj` project using Xcode.

```bash
$ git clone https://github.com/firebase/quickstart-ios.git
$ cd database/DatabaseExampleSwiftUI/DatabaseExample
$ open DatabaseExample.xcodeproj
```
- Once the `.xcodeproj` is opened, update to the latest Swift Package Versions: go to the menu bar,
  click on File > Swift Packages > Update to Latest Package Versions 

### Connecting to the Firebase Console 

- To have a functional application, you will need to connect the Database quickstart example with
  the [Firebase Console](https://console.firebase.google.com).
- For an in-depth explanation, you can read more about [adding Firebase to your iOS
  Project](https://firebase.google.com/docs/ios/setup). Below is a summary of the main steps:
  1. Visit the [Firebase Console](https://console.firebase.google.com) 
  2. Add an iOS app to the project. Make sure the `Bundle Identifier` you set for this iOS App
     matches that of the one in this quickstart.
  3. Download the `GoogleService-Info.plist` when prompted.
  4. Drag the downloaded `GoogleService-Info.plist` into the opened quickstart app under the
     `Shared` folder.
- [Create a Database](https://firebase.google.com/docs/database/ios/start#create_a_database) and
  update the rules to [database rules](./DatabaseExampleRules.md).
- Now you should be able to build and run the Firebase project!

### Navigation Bar Issue on tvOS
When using earlier versions of xcode (12.5 or below) there is a bug where SwiftUI toolbar disappears
after navigation on tvOS. This issue is resolved when using the latest version of xcode (13.5 or
above).

Documentation
-------------

- To learn more about the structure of the SwiftUI Realtime Database quickstart app, check out the
documentation [here](./OUTLINE.md).
- For demos and screenshots of the Quickstart from multiple Apple platforms, check out the
  documentation [here](./MEDIA.md)

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
