# Firebase App Distribution Quickstart

The Firebase App Distribution SDK enables you to display in-app alerts to your testers when new builds of your app are available to install. This quickstart aims to showcase how to use the App Distribution SDK to create and customize new build alerts for your testers. You can read more 
about Firebase App Distribution [here](https://firebase.google.com/docs/app-distribution)!

## Getting Started

Ready? Let's get started! 🚀

Clone this project and `cd` into the `AppDistributionExample` directory. 
Run `pod install`. This command will install all of the required cocoapods
for this quickstart and generate a `.xcworkspace` project. Go ahead and
open the `AppDistributionExample.xcworkspace` project.

### Terminal commands to clone and open the project!
```bash

$ git clone https://github.com/firebase/quickstart-ios.git

$ cd appdistribution/

$ pod install

$ open AppDistributionExample.xcworkspace

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
to `File`-> `Add Files to 'AppDistributionExample'` and selecting the 
downloaded `.plist` file. Be sure to add the `.plist` file to the app's main target.

5. At this point, you can build and run the quickstart! 🎉

## Distributing a Build

https://firebase.google.com/docs/app-distribution/ios/distribute-console

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
