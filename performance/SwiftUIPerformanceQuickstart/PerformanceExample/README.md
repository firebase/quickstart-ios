# Firebase Performance Monitoring Quickstart

## Firebase Performance Monitoring

Firebase Performance Monitoring is a free mobile app performance analytics service. It 
provides detailed information about the performance of your apps (app start, network requests, 
screen performance) automatically, while also allowing you to measure the performance of any piece 
of code in your apps.

See [OUTLINE.md](OUTLINE.md) for information on the design of the app, screenshots, and symbol 
references.

## Getting Started

- [Add Firebase to your iOS / tvOS Project](https://firebase.google.com/docs/ios/setup).
- [Create a default Cloud Storage bucket](https://firebase.google.com/docs/storage/ios/start#create-default-bucket).
- [Replace your Storage Security Rules](https://firebase.google.com/docs/storage/security/get-started#access_your_rules) with the following:
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /saliency_map.jpg {
      allow create: if request.resource.contentType == 'image/jpeg'
    }
  }
}
```
**Warning:** *these rules do not follow security best practices and are only intended for demonstration purposes. Please read more on why these rules are not secure [here](https://firebase.google.com/docs/rules/insecure-rules#open_access).*
- Run the sample on your iOS / tvOS device or simulator.
  - If your build fails due to package errors, try resetting package caches (File > Swift Packages > Reset Package Caches).


## Support

- [Firebase Support](https://firebase.google.com/support/)

## License

Copyright 2021 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
