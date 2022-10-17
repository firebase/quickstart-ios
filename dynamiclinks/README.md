Firebase Dynamic Links Quickstart
=============================

Introduction
------------

- [Read more about Firebase Dynamic Links](https://firebase.google.com/docs/dynamic-links)

Getting Started
---------------

- [Add Firebase to your iOS Project](https://firebase.google.com/docs/ios/setup).
- Follow the [quickstart guide](https://firebase.google.com) to set up your project.
- Paste your Dynamic Link Domain from Firebase Console to
  - **DynamicLinksExample.entitlements** file
  - **DOMAIN_URI_PREFIX** constant in ViewController.m and ViewController.swift files
  - **domainURIPrefix** constant in DynamicLinksExampleApp.swift file
- Run the sample on your iOS device.
- Create a Dynamic Link 
  - in the App or
  - in the **Dynamic Links** section of the Firebase console.
    - Custom Schemes of the form dlscheme://<data-to-pass>/<to-app> would be handled
      by the app. You can change dlscheme to fit your needs.
    - For Universal Links be sure to add your APP ID or TEAM ID to your app when
      connecting. The apple-app-site-association file will be generated and
      hosted automatically.
    - As of iOS 9, only Universal Links are considered strong links.
- From another application like Safari or Notes, you should be able to select
  your Dynamic Link and be taken to the quickstart app.

Note: You will need a device running iOS 11.0+ for the ObjC and Swift (UIKit)
versions of the quickstart, or iOS 14.0+ for the Swift (SwiftUI) version.

Screenshots
-----------

Support
-------

- [Firebase Support](https://firebase.google.com/support/)

License
-------

Copyright 2015 Google, Inc.

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
