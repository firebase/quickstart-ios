
# Firebase Auth Quickstart

  

This Firebase quickstart is written in Swift and aims to showcase how Firebase Auth can help manage user authentication. You can read more about Firebase Auth [here]()!

To view the older Objective-C and Swift quickstarts, view the [`AuthLegacyQuickstart`]() directory.

## Getting Started

Firebase Auth offers multiple ways to authenticate users. In this quickstart, we demonstrate how you can use Firebase Auth to authenticate users by providing implementations for the various authentication flows. Since each Firebase Auth flow is different, each may require a few extra steps to set everything up. Feel free to follow along and configure as many authentication flows as you would like to demo!  

Ready? Let's get started! 🏎💨

Clone this project and `cd` into the `AuthenticationExample` directory. Run `pod install`. This command will install all of the required cocoapods for this quickstart and generate a `.xcworkspace` project. Go ahead and open the `AuthenticationExample.xcworkspace` project.

### Terminal commands to clone and open the project!
```bash

$ git clone https://github.com/firebase/quickstart-ios.git

$ cd authentication/

$ pod install

$ open AuthenticationExample.xcworkspace

```

## Connecting to the Firebase Console

We will need to connect our quickstart with the Firebase Console. For an in depth explanation, you can read more about [adding Firebase to your iOS Project](https://firebase.google.com/docs/ios/setup).

### Here's a summary of the steps!
1. Visit the [Firebase Console]() and create a new app.
2. Add an iOS app to the project. Make sure the `Bundle Identifier` you set for this iOS App matches that of the one in this quickstart.
3. Download the `GoogleService-Info.plist` when prompted.
4. Drag the downloaded `GoogleService-Info.plist` into the opened quickstart app. You can also add this file to the project by going to `File`-> `Add Files to 'AuthenticationExample'` and selecting the downloaded `.plist` file.
5. At this point, you can build and run the quickstart! 🎉


## Configuring Identity Providers

To enable sign in with each of the following identity providers, there are a few configuration steps required to make sure everything works properly.

**When it comes to configuring most of the below identity providers**, you may have to have to [add a custom URL scheme](https://developer.apple.com/documentation/uikit/inter-process_communication/allowing_apps_and_websites_to_link_to_your_content/defining_a_custom_url_scheme_for_your_app) in your Xcode project so Firebase Auth can correctly work with the corresponding Identity Provider. This is done by selecting the app's target in Xcode and navigating to the **Info** tab. For each login flow that requires adding a custom URL scheme, be sure to add a new URL Scheme for each respective identity provider rather than replace existing schemes you have created previously. 
  

### Google Sign In

We have already included the **`GoogleSignIn`** cocoapod in the quickstart's `Podfile`. This cocoapod is **required** for **Google Sign In**.

#### Start by going to the [Firebase Console](https://console.firebase.google.com) and navigate to your project:

- Select the **Auth** panel and then click the **Sign In Method** tab.

- Click **Google** and turn on the **Enable** switch, then click **Save**.

- In Xcode, [add a custom URL scheme for your reversed client ID](https://developers.google.com/identity/sign-in/ios/start-integrating#add_a_url_scheme_to_your_project).

    - You can find this in the `GoogleService-Info.plist`. This is the value associated with the **`REVERSED_CLIENT_ID`** key in the  `GoogleService-Info.plist` file. 
    - For the `URL Type`'s **Identifier**, feel free to put whatever. Something like "Google Sign In" adds some context for what the reversed link is related to.
    - In Xcode, select the quickstart's target and navigate to the `Info` tab. Look for the `URL Types` section. Expand the section and select the first 'URL Type' and paste in the URL 

- Run the app on your device or simulator.

- Choose **Google** under **Identity Providers** to launch the Google Sign In flow

  

### Sign in with Apple

#### Start by going to the [Firebase Console](https://console.firebase.google.com) and navigate to your project:

- Select the **Auth** panel and then click the **Sign In Method** tab.
- Click **Apple** and turn on the **Enable** switch, then click **Save**.
- Run the app on your device or simulator.
- Select **Sign In** and select Apple to begin.
- See the [Getting Started with Apple Sign In guide](https://firebase.google.com/docs/auth/ios/apple) for more details.

As outlined in the docs, **Sign in with Apple** requires enabling the *Sign In with Apple* [`Capability`](https://developer.apple.com/documentation/xcode/adding_capabilities_to_your_app) in this quickstart's Xcode project. 

### Twitter
#### Start by going to the [Firebase Console](https://console.firebase.google.com) and navigate to your project:
  - Select the **Auth** panel and then click the **Sign In Method** tab.
  - Click **Twitter** and turn on the **Enable** switch, then click **Save**.
  - Enter your Twitter **API Key** and **App Secret** and click **Save**.
  - Make sure your Firebase OAuth redirect URI (e.g. my-app-12345.firebaseapp.com/__/auth/handler) is set as your  
    Authorization callback URL in your app's settings page on your [Twitter app's config](https://apps.twitter.com).
- Run the app on your device or simulator.
    - Select **Sign In** and select Twitter to begin.
  

### Microsoft
#### Start by going to the [Firebase Console](https://console.firebase.google.com) and navigate to your project:
- Select the **Auth** panel and then click the **Sign In Method** tab.
  - Click **Microsoft** and turn on the **Enable** switch, then click **Save**.
- In Xcode, [add a custom URL scheme for your reversed client ID](https://developers.google.com/identity/sign-in/ios/start-integrating).
  - You can find this in the `GoogleService-Info.plist`
- Run the app on your device or simulator.
    - Select **Sign In** and select Microsoft to begin.

See the [Getting Started with Microsoft Sign In guide](https://firebase.google.com/docs/auth/ios/microsoft-oauth) for more details.

  
### GitHub
#### Start by going to the [Firebase Console](https://console.firebase.google.com) and navigate to your project:
- Select the **Auth** panel and then click the **Sign In Method** tab.
  - Click **GitHub** and turn on the **Enable** switch, then click **Save**.
- In Xcode, [add a custom URL scheme for your reversed client ID](https://developers.google.com/identity/sign-in/ios/start-integrating).
  - You can find this in the `GoogleService-Info.plist`
- Run the app on your device or simulator.
    - Select **Sign In** and select GitHub to begin.
   
See the [Getting Started with GitHub Sign In guide](https://firebase.google.com/docs/auth/ios/github-auth) for more details.

### Yahoo
#### Start by going to the [Firebase Console](https://console.firebase.google.com) and navigate to your project:
- Select the **Auth** panel and then click the **Sign In Method** tab.
  - Click **Yahoo** and turn on the **Enable** switch, then click **Save**.
- In Xcode, [add a custom URL scheme for your reversed client ID](https://developers.google.com/identity/sign-in/ios/start-integrating).
  - You can find this in the `GoogleService-Info.plist`
- Run the app on your device or simulator.
    - Select **Sign In** and select Yahoo to begin.
  
See the [Getting Started with Yahoo Sign In guide](https://firebase.google.com/docs/auth/ios/yahoo-oauth) for more details.

### Facebook

We have already included the **`FBSDKLoginKit`** cocoapod in the quickstart's `Podfile`. This cocoapod is **required** for **Sign In with Facebook**.

- Go to the [Facebook Developers Site](https://developers.facebook.com) and follow all
  instructions to set up a new iOS app. When asked for a bundle ID, use
  `com.google.firebase.quickstart.AuthenticationExample`.
- Go to the [Firebase Console](https://console.firebase.google.com) and navigate to your project:
  - Select the **Auth** panel and then click the **Sign In Method** tab.
  - Click **Facebook** and turn on the **Enable** switch, then click **Save**.
  - Enter your Facebook **App Id** and **App Secret** and click **Save**.
 TODO: Maybe suggest adding this to peformFacebookLoginFlow()
- Open your regular `Info.plist` and replace the value of the `FacebookAppID` with the ID of the
  Facebook app you just created, e.g 124567. Save that file.
- In the *Info* tab of your target settings add a *URL Type* with a *URL Scheme* of 'fb' + the ID
  of your Facebook app, e.g. fb1234567.
- Run the app on your device or simulator.
    - Select **Sign In** and select Facebook to begin.
  
### Email/Password Setup
#### Start by going to the [Firebase Console](https://console.firebase.google.com) and navigate to your project:
  - Select the **Auth** panel and then click the **Sign In Method** tab.
  - Click **Email/Password** and turn on the **Enable** switch, then click **Save**.
- Run the app on your device or simulator.
    - Select **Sign In** and select Email to begin.
 
  

## Other Auth Methods

  

### Email Link/Passwordless

Email Link authentication, which is also referred to as Passwordless authentication, works by sending a verification email to a user requesting to sign in. This verification email contains a special `Dynamic Link` that links the user back to your app, completing authentication in the process. In order to configure this method of authentication, we will use [Firebase Dynamic Links](link), which we will need to set up.

If this is your first time working with Dynamic Links, here's a great [introduction](link). Note, we will outline most of the steps covered in this tutorial below!

#### Start by going to the [Firebase Console](https://console.firebase.google.com) and navigate to your project:
  - Select the **Auth** panel and then click the **Sign In Method** tab.
  - Click **Email/Password** and ensure it is enabled.
  - Turn on **Email link (passwordless sign-in)**, then click **Save**.
  - Configure **Dynamic Links**, by enabling it in the Firebase console

- Run the app on your device or simulator.
    - Select **Email Link /Passwordless** and this will present a login screen where you can enter an email for the verification to be sent to
    - Enter an email and tap **Send Sign In Link**. While keeping the current view controller displayed, switch to a mail app and wait to receive the verification email.
    - Once the email has been received, open it and tap the sign in link. This will link back to the quickstart and finish the login flow.

#### Setup
TODO:
1. Firebase Console -> Email Password -> Select Passwordless

2. Enable Dynamic Links

3. Create a dynamic link

4. Associated Domains in Capabilities (add the dynamic links domain)

  

  

### So how does this work?

We will start by taking a look at `PasswordlessViewController.swift`. If you are currently running the quickstart app, select the "Email Link/Passwordless" authentication option.  

The user is prompted for an email to be used in the verification process. When  the "Send Sign In Link" button is tapped, we configure our verification link by adding the user's email to the dynamic link we created earlier. Then we send a send the link to the user's email. You can edit the format of these verification emails on the [Firebase Console](link!).

 
When the user receives the verification email, they can open the link contained in the email to be redirected back to the app (using the power of [Dynamic Links]() 😎. On apps using the [`SceneDelegate`]() API,  opening the incoming dynamic link will be handled in `UIWindowSceneDelegate`'s  `func scene(_ scene: UIScene, continue userActivity: NSUserActivity)` method. This method can be implemented in  `SceneDelegate.swift`. Since the quickstart uses the `SceneDelegate` API, you can check out the implementation [here](). We basically pass the incoming link to a helper method that will do a few things:

  

```swift
// SceneDelegate.swift

private func handleIncomingDynamicLink(_ incomingURL: URL) {

    DynamicLinks.dynamicLinks().handleUniversalLink(incomingURL) { (dynamicLink, error) in

    // Handle the potential `error`

    guard let link = dynamicLink?.url?.absoluteString else { return }

    // Here, we check if our dynamic link is a sign-link (the one we emailed our user!)
    if Auth.auth().isSignIn(withEmailLink: link) {

        // Save the link as it will be used in the next step to complete login
        UserDefaults.standard.set(link, forKey: "Link")

        // Post a notification to the PasswordlessViewController to resume authentication
        NotificationCenter.default.post(Notification(name: Notification.Name("PasswordlessEmailNotificationSuccess")))
        }
    }
}
```

If the incoming dynamic link is a sign-in link, then we post a notification that pretty much says: "Hey! A user just opened a verification dynamic link that we emailed them and we need to complete the authentication!"

This takes us back to our  `PasswordlessViewController.swift`, where [we registered for this exact notification](link)! When the notification is posted, we will receive it here and call the `passwordlessSignIn()` method to complete the authentication. In this method, we used Firebase Auth's `Auth.auth().signIn(withEmail: String, link: String)` which, behind the scenes, checks that this link was the link we originally sent to the associated email and if so, signs in the user! 🥳

  
### Phone Number

When Firebase Auth uses Phone Number authentication, Auth will attempt to send a silent Apple Push Notification (APN) to the device to confirm that the phone number being used is associated with the device. If APNs (which, like Sign In with Apple, are a [capability](https://developer.apple.com/documentation/xcode/adding_capabilities_to_your_app) you can enable in Xcode or on the Apple Developer Console) are not enabled or configured correctly, Auth will instead present a web view with a reCAPTCHA verification flow. 

#### Start by going to the [Firebase Console](https://console.firebase.google.com) and navigate to your project:
  - Select the **Auth** panel and then click the **Sign In Method** tab.
  - Click **Anonymous** and turn on the **Enable** switch, then click **Save**. See the official [Firebase docs](link!) for more info!
  

### Anonymous Authentication
#### Start by going to the [Firebase Console](https://console.firebase.google.com) and navigate to your project:
  - Select the **Auth** panel and then click the **Sign In Method** tab.
  - Click **Anonymous** and turn on the **Enable** switch, then click **Save**.
  

### Custom Auth System

Firebase Auth can manage authentication for use cases that utilize a custom auth system. Ensure you have an authentication server capable of producing custom signed tokens. When a user signs in, make a request for a signed token from your authentication server.

After your server returns the token, pass that into  Firebase Auth's `signIn(withCustomtoken: String)` method to complete the authentication process. In the quickstart, you can demo signing in with tokens you generate. See `CustomAuthViewController.swift` for more info.

If you wish to setup a custom auth system. The below steps can help in its configuration.

**Go to the [Google Developers Console](https://console.developers.google.com/project) and create a project**:
    - From the left "hamburger" menu navigate to the **API Manager** tab.
    - Click on the **Credentials** item in the left column.
    - Click **New credentials** and select **Service account key**. Select **New service account**,
    pick any name, and select **JSON** as the key type. Then click **Create**.
    - You should now have a new JSON file for your service account in your Downloads directory.
- Open the file `web/auth.html` in your computer's web browser.
    - Click **Choose File** and upload the JSON file you just downloaded.
    - Enter any User ID and click **Generate**.
    - Copy the token link displayed.
- Run the app on your device or simulator.
    - Select **Custom Auth system**
    - Paste in the token you generated earlier.
    - When you return to the main screen, you should see the User ID you entered when generating the
      token.
  

# Support

-  [Firebase Support](https://firebase.google.com/support/)

  

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
