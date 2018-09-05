Firebase Messaging Quickstart
=============================

The Firebase Messaging iOS Quickstart app demonstrates how to connect
an iOS app to FCM and how to receive messages.

Introduction
------------

- [Read more about Firebase Messaging](https://firebase.google.com/docs/cloud-messaging)

Best Practices
--------------

- In this sample the request for permission to receive remote notifications
  is made on first run, this results in a permission dialog on first run.
  Most apps would want that dialog to be shown at a more appropriate time. So
  move the registration for remote notifications to a more appropriate place in
  your app.

Getting Started
---------------

- Add APNS certs to your project in **Project Settings** > **Notifications** in the [console](https://console.firebase.google.com)
- Run `pod install --repo-update`
- Copy in the GoogleServices-Info.plist to your project
- Update the app Bundle ID in Xcode to match the Bundle ID of your APNs cert.
- Run the sample on your iOS device.

Note:
- You will need Swift 3.0 to run the Swift version of this quickstart.
- APS Environment Entitlements are required for remote notifications as of Xcode 8.
  Ensure that Push Notifications are on without error in App > Capabilities.

Screenshots
-----------

Support
-------

- [Firebase Support](https://firebase.google.com/support/)

License
-------

Copyright 2016 Google, Inc.

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
