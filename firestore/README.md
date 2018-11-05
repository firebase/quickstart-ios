# Friendly Eats
## Introduction
Friendly Eats is a restaurant recommendation app built on Cloud Firestore.
For more information about Firestore visit [the docs][firestore-docs].
## Setup
  * [Set up your iOS app for Cloud Firestore][setup-ios]
  * In the Authentication tab of the Firebase console go to the
    [Sign-in Method][auth-providers] page and enable 'Email/Password'.
    * This app uses [FirebaseUI][firebaseui] for authentication.
  * Run the app on an iOS device or emulator.

## Getting Started
  * When you open the app you will be prompted to sign in, choose
    any email and password.
  * When you first open the app it will be empty, press the
    **Populate** button in the top left.
  * Modify your Firestore security rules to allow reading and writing reviews and restaurants. Take a look at the rules below for reference.

## Rules

Here's an adequate set of rules for running FireEats.

```
service cloud.firestore {
  match /databases/{database}/documents {
    match /restaurants/{restaurant} {
      match /ratings/{rating} {
        allow read: if request.auth != null;
        allow write: if request.auth != null 
                     && request.auth.uid == request.resource.data.userId;
      }

      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null
                    && request.resource.data.name == resource.data.name
                    && request.resource.data.city == resource.data.city
                    && request.resource.data.price == resource.data.price
                    && request.resource.data.category == resource.data.category;
    }
  }
}
```

## Indexes
As you use the app's filter functionality you may see warnings
in logcat that look like this:
```
Error fetching snapshot results: Error Domain=io.grpc Code=9 "The query requires an index. You can create it here: https://console.firebase.google.com/project/testapp-5d356/database/firestore/indexes?create_index=..." UserInfo={NSLocalizedDescription=The query requires an index. You can create it here: https://console.firebase.google.com/project/testapp-5d356/database/firestore/indexes?create_index=...}
```
This is because indexes are required for most compound queries in
Cloud Firestore. Opening the link from the error message will
automatically open the index creation UI in the Firebase console
with the correct parameters filled in.

[firestore-docs]: https://firebase.google.com/docs/firestore/
[setup-ios]: https://firebase.google.com/docs/firestore/client/setup-ios
[auth-providers]: https://console.firebase.google.com/project/_/authentication/providers
[firebaseui]: https://github.com/firebase/FirebaseUI-iOS
