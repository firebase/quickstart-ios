Firebase App Indexing Quickstart
==============================

The Firebase App Indexing iOS quickstart demonstrates how to help get your app found in Google Search.

Introduction
------------

- [Read more about Firebase App Indexing](https://firebase.google.com)

Getting Started
---------------

- [Add Firebase to your iOS Project](https://firebase.google.com/docs/ios/setup).
- In web/public/apple-app-site-association file, replace <YOUR-APPID-OR-TEAMID> with your
  App ID or your Team ID.
- Get the [Firebase Command Line Interface (CLI)](https://firebase.google.com/docs/hosting/quickstart#install-the-firebase-cli) Step 1
- Run `firebase init`
  - Select your current Firebase project
  - Hit Enter to select the default public directory as your website root.
- Run `firebase deploy`
- In the **Capabilities** tab of XCode, turn on **Associated Domains**. Add
  your Firebase hosting domain in the format applinks:<YOUR-DOMAIN>. Do not include "https://".
  You can find your Firebase hosting domain in the Hosting section of the
  Firebase console.
- Run the sample on your iOS device.
- From Safari on your iOS device, go to your Firebase hosting URL.
- Select one of the available links, *Go to content* or *Go to other content*
  - If you are not automatically redirected to the app, swipe down in Safari to
    reveal the *OPEN* option that takes you to the app.
- Verify that the deep link data matches the link clicked.

Note: You will need Swift 2.0 to run the Swift version of this quickstart.

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
