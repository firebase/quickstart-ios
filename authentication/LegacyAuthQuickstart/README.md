Firebase Authentication Quickstart
=============================

Introduction
------------

- [Read more about Firebase Authentication](https://firebase.google.com/docs/auth/)

Getting Started
---------------

- [Add Firebase to your iOS Project](https://firebase.google.com/docs/ios/setup).


### Google Sign In Setup
- Go to the [Firebase Console](https://console.firebase.google.com) and navigate to your project:
  - Select the **Auth** panel and then click the **Sign In Method** tab.
  - Click **Google** and turn on the **Enable** switch, then click **Save**.
- In Xcode, [add a custom URL scheme for your reversed client ID](https://developers.google.com/identity/sign-in/ios/start-integrating).
  - You can find this in the `GoogleService-Info.plist`
- Run the app on your device or simulator.
    - Select **Sign In** and select Google to begin.

### Sign in with Apple Setup
- Go to the [Firebase Console](https://console.firebase.google.com) and navigate to your project:
  - Select the **Auth** panel and then click the **Sign In Method** tab.
  - Click **Apple** and turn on the **Enable** switch, then click **Save**.
- Run the app on your device or simulator.
    - Select **Sign In** and select Apple to begin.
- See the [Getting Started guide](https://firebase.google.com/docs/auth/ios/apple) for more details.

### Microsoft Sign In Setup
- Go to the [Firebase Console](https://console.firebase.google.com) and navigate to your project:
  - Select the **Auth** panel and then click the **Sign In Method** tab.
  - Click **Microsoft** and turn on the **Enable** switch, then click **Save**.
- In Xcode, [add a custom URL scheme for your reversed client ID](https://developers.google.com/identity/sign-in/ios/start-integrating).
  - You can find this in the `GoogleService-Info.plist`
- Run the app on your device or simulator.
    - Select **Sign In** and select Microsoft to begin.

### Facebook Login Setup
- Go to the [Facebook Developers Site](https://developers.facebook.com) and follow all
  instructions to set up a new iOS app. When asked for a bundle ID, use
  `com.google.firebase.quickstart.AuthenticationExample`.
- Go to the [Firebase Console](https://console.firebase.google.com) and navigate to your project:
  - Select the **Auth** panel and then click the **Sign In Method** tab.
  - Click **Facebook** and turn on the **Enable** switch, then click **Save**.
  - Enter your Facebook **App Id** and **App Secret** and click **Save**.
- Open your regular `Info.plist` and replace the value of the `FacebookAppID` with the ID of the
  Facebook app you just created, e.g 124567. Save that file.
- In the *Info* tab of your target settings add a *URL Type* with a *URL Scheme* of 'fb' + the ID
  of your Facebook app, e.g. fb1234567.
- Run the app on your device or simulator.
    - Select **Sign In** and select Facebook to begin.

### Email/Password Setup
- Go to the [Firebase Console](https://console.firebase.google.com) and navigate to your project:
  - Select the **Auth** panel and then click the **Sign In Method** tab.
  - Click **Email/Password** and turn on the **Enable** switch, then click **Save**.
- Run the app on your device or simulator.
    - Select **Sign In** and select Email to begin.

### Multi Factor Authentication
**Note**: Multi Factor authentication only works for apps using [Google Cloud Identity Platform](https://cloud.google.com/identity-platform/docs/ios/mfa),
a paid service. If you are only using Firebase Authentication this sample will not work for you.

- Run the app on your device
    - Select **Email (with MFA)** from the main screen.
    - Sign in (if necessary).
    - Verify your email (if necessary).
    - Hit **Enroll MFA** to begin enrolling an SMS second factor.

### Twitter Login Setup
- [Register your app](https://apps.twitter.com) as a developer application on Twitter and get your
  app's OAuth API key and API secret.
- Go to the [Firebase Console](https://console.firebase.google.com) and navigate to your project:
  - Select the **Auth** panel and then click the **Sign In Method** tab.
  - Click **Twitter** and turn on the **Enable** switch, then click **Save**.
  - Enter your Twitter **API Key** and **App Secret** and click **Save**.
  - Make sure your Firebase OAuth redirect URI (e.g. my-app-12345.firebaseapp.com/__/auth/handler) is set as your  
    Authorization callback URL in your app's settings page on your [Twitter app's config](https://apps.twitter.com).
- Run the app on your device or simulator.
    - Select **Sign In** and select Twitter to begin.

### Custom Authentication Setup
- Go to the [Google Developers Console](https://console.developers.google.com/project) and navigate to your project:
    - From the left "hamburger" menu navigate to the **API Manager** tab.
    - Click on the **Credentials** item in the left column.
    - Click **New credentials** and select **Service account key**. Select **New service account**,
    pick any name, and select **JSON** as the key type. Then click **Create**.
    - You should now have a new JSON file for your service account in your Downloads directory.
- Open the file `web/auth.html` in your computer's web browser.
    - Click **Choose File** and upload the JSON file you just downloaded.
    - Enter any User ID and click **Generate**.
    - Copy the token link displayed.
- Run the app on the simulator.
    - Select **Sign In** and select Custom to begin.
    - Paste in the token you generated earlier.
    - When you return to the main screen, you should see the User ID you entered when generating the
      token.

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
