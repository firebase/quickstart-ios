# Firebase AI Quickstart

This sample demonstrates how to make calls to the Gemini API via Firebase directly
from your app, rather than server-side, using the
[Vertex AI for Firebase SDK](https://firebase.google.com/docs/vertex-ai/get-started?platform=ios).

## Getting Started

### Clone and open the sample project

1. Clone this repo.
1. Change into the `firebaseai` directory.
1. Open `FirebaseAIExample.xcodeproj` using Xcode.
   ```bash
   git clone https://github.com/firebase/quickstart-ios.git
   cd quickstart-ios/firebaseai
   open FirebaseAIExample.xcodeproj
   ```
1. Select the `FirebaseAIExample (iOS)` scheme in Xcode to build the app using
   the Swift Package Manager distribution.

### Connect the sample to your Firebase project

To have a functional application, you will need to connect the Firebase AI
sample app to your Firebase project (or create a new project):

1. Follow the instructions in
   [Set up a Firebase project and connect your app to Firebase](https://firebase.google.com/docs/vertex-ai/get-started?platform=ios#set-up-firebase).
2. Add an iOS+ app to your project. Make sure the `Bundle Identifier` you set
   matches the one in the sample.
     - The default bundle ID is `com.google.firebase.quickstart.FirebaseAIExample`
3. Download the `GoogleService-Info.plist` for the app when prompted and save
   it to the `firebaseai` directory.

You should now be able to build and run the sample!

### Request logging

The `-FIRDebugEnabled` option is set as a command line argument in the build
scheme to log server requests to the console. Remove the option to turn off the
logging.

### Firebase App Check

This sample app has Firebase App Check enabled by default using the `AppCheckDebugProviderFactory` to protect your Vertex AI / Gemini API resources from abuse during local development.

To make successful API requests when running the app:
1. Locate the generated local debug token in your Xcode console output (look for a line like: `[Firebase/AppCheck] App Check debug token: <YOUR_TOKEN>`).
2. Copy this token.
3. Register the token in the [Firebase Console](https://console.firebase.google.com/) under **App Check** > **Apps** > **Manage debug tokens** for your app.

For more details, see the official guide: [Use the App Check debug provider on iOS](https://firebase.google.com/docs/app-check/ios/debug-provider).

#### Usability Tip: Pinned Debug Token for Simulators
To avoid registering a new random debug token every time you restart/reset a simulator, you can configure a fixed (pinned) debug token in Xcode:
1. In the Firebase Console, generate a custom debug token.
2. In Xcode, edit your active build scheme (**Product** > **Scheme** > **Edit Scheme...**).
3. Under the **Run** section, select the **Arguments** tab.
4. Add `-AppCheckDebugToken <YOUR_CUSTOM_TOKEN>` to the **Arguments Passed On Launch** section.

#### WARNING: Production Deployment
The App Check debug provider is only intended for development/testing environments. Before distributing your app to the App Store, you must migrate to a production-grade provider (such as **AppAttest** or **DeviceCheck**). Refer to the following guides:
- [Use App Attest on iOS](https://firebase.google.com/docs/app-check/ios/app-attest-provider)
- [Use DeviceCheck on iOS](https://firebase.google.com/docs/app-check/ios/devicecheck-provider)

## Documentation

To learn more about the Firebase AI SDK, check out the
[documentation](https://firebase.google.com/docs/vertex-ai).

## Support

- [GitHub Issue](https://github.com/firebase/firebase-ios-sdk/issues/new/choose)
  - File an issue in the `firebase-ios-sdk` repo, choosing the Firebase AI product.
- [Firebase Support](https://firebase.google.com/support/)
