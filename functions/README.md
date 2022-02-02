Firebase Functions Quickstart
=============================

Introduction
------------

This quickstart demonstrates **Callable Functions** which are HTTPS Cloud Functions
that can be invoked directly from your mobile application.

- [Read more about callable functions](https://firebase.google.com/docs/functions/callable)

Getting Started
---------------

- [Add Firebase to your iOS Project](https://firebase.google.com/docs/ios/setup).
- [Set up Firebase Functions](https://firebase.google.com/docs/functions/get-started)
Functions in the docs should be updated, since the functions applied in the
quickstart might not be the same as the ones in the example from the doc above.

To align with the quickstart, the `index.js` should be updated to
```js
const functions = require('firebase-functions');

exports.addNumbers = functions.https.onRequest((request, response) => {
  var first = Number(request.body.data.firstNumber);
  var second = Number(request.body.data.secondNumber);
  response.json({ data: {operationResult: first + second} });
});

exports.capitalizeMessage = functions.https.onRequest((request, response) => {
  var upText = request.body.data.text;
  response.json({ data: {text: upText.toUpperCase()} });
});
```
- Run on a local machine
To let the quickstart run on a local machine, you can [Emulate execution of your functions](https://firebase.google.com/docs/functions/get-started#emulate-execution-of-your-functions)
locally by adding a flag `-D EMULATOR` to the `Other Swift Flags` under the
`Build Settings`.

- Run in production
Once functions are [deployed to a production environment](https://firebase.google.com/docs/functions/get-started#deploy-functions-to-a-production-environment),
the Functions quickstart can just build and run without additional settings to
connect to a Firebase project. Remember to remove the `-D EMULATOR` flag if you
ran the quickstart through an emulator before.

Support
-------

- [Stack Overflow](https://stackoverflow.com/questions/tagged/google-cloud-functions)
- [Firebase Support](https://firebase.google.com/support/)

License
-------

Copyright 2022 Google, Inc.

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
