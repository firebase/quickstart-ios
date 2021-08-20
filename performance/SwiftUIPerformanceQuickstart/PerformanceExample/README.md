Firebase Performance Monitoring Quickstart
=============================

# Firebase Performance Monitoring

Firebase Performance Monitoring is a free mobile app performance analytics service. It
provides detailed information about the performance of your apps (app start, network requests, screen performance) automatically,
while also allowing you to measure the performance of any piece of code in your apps.

Introduction
------------

- [Read more about Firebase Performance Monitoring](https://firebase.google.com/docs/perf-mon/)

Getting Started
---------------

- [Add Firebase to your iOS / tvOS Project](https://firebase.google.com/docs/ios/setup).
- [Create a default Cloud Storage bucket](https://firebase.google.com/docs/storage/ios/start#create-default-bucket).
- [Replace your Rules](https://firebase.google.com/docs/storage/security/get-started#access_your_rules) with the following:
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
- Run the sample on your iOS / tvOS device or simulator.


Support
-------

- [Firebase Support](https://firebase.google.com/support/)

License
-------

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
