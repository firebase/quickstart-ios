Firebase Custom Auth Quickstart
=============================

The Firebase custom auth iOS quickstart demonstrates how to authenticate with the Firebase user management
system with a user who has been authenticated from your own pre-existing authentication system. 

This is done by generating a token in a specific format, which is signed using the private key from a 
service account downloaded from the Google Developer Console. This token can then be passed to your client
application which uses it to authenticate to Firebase. 

Introduction
------------

- [Read more about Firebase Custom Auth](https://developers.google.com/firebase)

Getting Started
---------------

- [Add Firebase to your iOS Project](https://developers.google.com/firebase/docs/ios/setup).
- Follow the [quickstart guide](https://developers.google.com/firebase) to set up your project, including
  downloading a service account JSON file for token generation. 
- Run the sample on the iOS simulator.
- Generate the token by opening the web/tokengenerator.html file in a browser, and uploading your
  service account JSON file. Enter a user ID and press 'Generate' to issue a token. 
- Copy into the simulator by selecting Edit > Paste, then clicking the text area and selecting the
  Past bubble that pops up. 

Note: You will need Swift 1.2 to run the Swift version of this quickstart.

Screenshots
-----------

Support
-------

https://developers.google.com/firebase/support/

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
