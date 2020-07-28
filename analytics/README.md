# Google Analytics for Firebase Quickstart

This Firebase quickstart is written in Swift and aims to showcase how Firebase 
Analytics can provide insight on app usage and user engagement. You can read more 
about Google Analytics for Firebase [here](https://firebase.google.com/docs/analytics)!

To view the older Objective-C and Swift quickstarts, view the 
[`LegacyAnalyticsQuickstart`](https://github.com/firebase/quickstart-ios/blob/master/analytics/LegacyAnalyticsQuickstart) 
directory.

## Getting Started

Google Analytics for Firebase offers multiple ways to understand how users are 
engaging with your app. In this quickstart, we demonstrate how you can use
Google Analytics for Firebase to log in-app events and set user properties.  

Ready? Let's get started! 🚀

Clone this project and `cd` into the `AnalyticsExample` directory. 
Run `pod install`. This command will install all of the required cocoapods
for this quickstart and generate a `.xcworkspace` project. Go ahead and
open the `AnalyticsExample.xcworkspace` project.

### Terminal commands to clone and open the project!
```bash

$ git clone https://github.com/firebase/quickstart-ios.git

$ cd analytics/

$ pod install --repo-update

$ open AnalyticsExample.xcworkspace

```

## Connecting to the Firebase Console

We will need to connect our quickstart with the 
[Firebase Console](https://console.firebase.google.com). For an in 
depth explanation, you can read more about 
[adding Firebase to your iOS Project](https://firebase.google.com/docs/ios/setup).

### Here's a summary of the steps!
1. Visit the [Firebase Console](https://console.firebase.google.com) 
and create a new app.

2. Add an iOS app to the project. Make sure the `Bundle Identifier` you
set for this iOS App matches that of the one in this quickstart.

3. Download the `GoogleService-Info.plist` when prompted.

4. Drag the downloaded `GoogleService-Info.plist` into the opened 
quickstart app. In Xcode, you can also add this file to the project by going
to `File`-> `Add Files to 'AnalyticsExample'` and selecting the 
downloaded `.plist` file. Be sure to add the `.plist` file to the app's main target.

5. At this point, you can build and run the quickstart! 🎉

## Interacting with the Quickstart

Google Analytics for Firebase is a great way to 
[log user related events](https://firebase.google.com/docs/analytics/events?platform=ios) 
or [set user properties](https://firebase.google.com/docs/analytics/user-properties?platform=ios). 
This quickstart features a number of different UI controls that a user can interact with. 
Depending on the control, Google Analytics for Firebase is used to either set a 
user property or log an appropriate event.

## Viewing the analytics data

### Debug Logging
Sometimes it is helpful to view debug logging when working with 
Google Analytics for Firebase. This can easily be enabled in Xcode by 
specifying `-FIRAnalyticsDebugEnabled` as a [runtime argument](http://goo.gl/RfcP7r). 
Using Xcode's menu bar, navigate to `Product` → `Scheme` → `Edit Scheme...`. 
Using the vertical menu on the left, select the **Run** scheme. 
Then click **Arguments** and add  `-FIRAnalyticsDebugEnabled` as an 
argument passed on launch. Done! ✓

### Firebase Console [DebugView](https://firebase.google.com/docs/analytics/debugview)

As you interact with the controls in the quickstart, analytics data will be sent to the 
Firebase Console. To view and interact with this stream, navigate to the project you
set up for this quickstart on the Firebase Console. Select **DebugView** under the
**Analytics** on the vertical menu on the left. From here, you can interact with the
quickstart and see the related analytics data show up live on the Firebase Console.  

# Support

- [Firebase Support](https://firebase.google.com/support/)

# License
  
Copyright 2020 Google LLC


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
