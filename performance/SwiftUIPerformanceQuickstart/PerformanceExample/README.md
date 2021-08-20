Firebase Performance Monitoring Quickstart
=============================

# Firebase Performance Monitoring

Firebase Performance Monitoring is a free mobile app performance analytics service. It
provides detailed information about the performance of your apps (app start, network requests, screen performance) automatically,
while also allowing you to measure the performance of any piece of code in your apps.

Introduction
------------
The app is centered around image tasks: download, classify, saliency map, and upload. Downloading
and uploading images is a common developer task. Classifying the image and generating a saliency map
are tasks that might be more popular now with the success of computer vision algorithms. Classifying
the image consists of providing categories to which the image belongs, while generating a saliency
map consists of producing a map that identifies the parts of an image most likely to draw attention.

Network requests are automatically traced by Performance Monitoring, while custom traces are used to
measure the classification task.

The typical usage flow consists of downloading the image, classifying the image, generating the
saliency map, and lastly uploading the saliency map. The status of the task (idle, running, success,
failure) is displayed for the user’s convenience.

- [Read more about Firebase Performance Monitoring](https://firebase.google.com/docs/perf-mon/)
- [Read more about Vision](https://developer.apple.com/documentation/vision)
  - [See code samples for classifying images](https://developer.apple.com/documentation/vision/classifying_images_for_categorization_and_search)
  - [See code samples for saliency maps](https://developer.apple.com/documentation/vision/highlighting_areas_of_interest_in_an_image_using_saliency)

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
