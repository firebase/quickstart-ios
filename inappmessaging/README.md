# In-App Messaging Quickstart
## Introduction
Firebase In-App messaging is a service allowing developers to send targeted
messages to users. To learn more, take a look at [the docs](https://firebase.google.com/docs/ios/setup).
## Setup
  * [Add Firebase to your iOS app][setup-ios].
  * In the root of the project, run `pod install --repo-update`.
  * Open the resulting `xcworkspace` and run the app on an iOS device or simulator.

## Getting Started
  * Open the In-App Messaging tab of [Firebase Console][firebase-console].
  * Click the "New Campaign" button to begin composing a new campaign.
  * Under **Style and Content**, Set the message's title to "Test Message" and
    its body to "Test successful!".
  * Under **Target**, enter "Test campaign" as the campaign name and target all
  * users of the iOS app of your Firebase project.
  * Under **Scheduling**, remove the `on_foreground` trigger and add a new
    trigger with a custon event named `test_event`. Leave other fields as-is.
  * Under **Conversion Events**, leave everything as is and hit Publish.
  * Quit and re-run the sample app and try pressing the "Trigger event" button.


[firestore-docs]: https://firebase.google.com/docs/firestore/
[setup-ios]: https://firebase.google.com/docs/ios/setup
[firebase-console]: https://console.firebase.google.com/project/_/inappmessaging
[firebaseui]: https://github.com/firebase/FirebaseUI-iOS
