Firebase Remote Config Quickstart
=============================

The Firebase Remote Config iOS quickstart app demonstrates using Remote
Config to define user-facing text in an iOS app.

Introduction
------------

This is a simple example of using Remote Config to override in-app default
values by defining service-side parameter values in the Firebase console. This
example demonstrates a small subset of the capabilities of Firebase Remote
Config. To learn more about how you can use Firebase Remote Config in your app,
see
[Firebase Remote Config Introduction](https://firebase.google.com/docs/remote-config/).

Getting started
---------------

1. [Add Firebase to your iOS Project](https://firebase.google.com/docs/ios/setup).
2. [Create a Remote Config project for the quickstart sample](https://firebase.google.com/docs/remote-config/ios#create_a_product_name_project_for_the_quickstart_sample),
   defining the parameter values and parameter keys used by the sample.
3. Run the sample on an iOS device or emulator.
4. Change one or more parameter values in the Firebase Console (the value of
  `topLabelKey`, `recipeKey`, and/or `bottomLabelKey`). This is discussed in detail in the next section!
5. Tap **Fetch & Activate Config** in the app to fetch new parameter values and see
  the resulting change in the app.

### Configuring the Quickstart with Remote Config
#### The Top Label - Configuring user-facing text
When you open the quickstart, you'll notice a label that greets you near the top of the display. Remote config is an excellent choice for configuring user-facing text so let's configure this label! Go to the Firebase Console and navigate to the remote config tab. Add a parameter with `topLabelKey` for the **Parameter Key**. For the **Default Value**, enter whatever text you would like! Make these changes live by clicking **Publish Changes** in the top right corner of the console. Switch back to the quickstart app and tap **Fetch & Activate Config**. The top label should update with the new value you set in the console!

#### Recipe View - Configuring Complex entities using JSON
Imagine your are building an app where each day, you display a "Recipe of the Day" to your users. Rather than configure lots of individual config keys and values, we can group a recipe's data together in one JSON object. 

In this quickstart, we provide you with a folder of JSON files called [JSON Recipes](https://github.com/firebase/quickstart-ios/tree/master/config/ConfigExample/JSON%20Recipes). Copy one on the recipes and navigate to the Remote Config tab of the Firebase Console. Let's add a parameter for the recipe. For the **Parameter Key**, enter `recipeKey` and for the value, click the **{}** button on the right of the **Default Value** text box. Paste the JSON recipe you copied earlier into this box and click **Save**. To make these changes live so our app can fetch them, click **Publish Changes** in the top right corner of the console.

Now that there is a recipe on to be fetched. Tap **Fetch & Activate Config** and the recipe you entered on the Firebase console will display on the device!

####  The Bottom Label - Defining platform and locale-specific content
You can add remote config values that will take effect based on certain conditions. Let's experiment with this by adding another remote config parameter. For the **Parameter Key**, enter `bottomLabelKey` and for the value, click the **Add value for condition** button. We encourage you to explore the remote config's capabilities by adding and publishing values that apply for certain conditions. For instance, maybe you want to display a special deal in specific regions of the world or at a certain date and time.


For more info on what you can do with remote config, checkout out this [Firebase article](https://firebase.google.com/docs/remote-config/use-cases).

Best practices
--------------
This section provides some additional information about how the quickstart
example sets in-app default parameter values and fetches values from the Remote
Config service.

### In-app default parameter values 

In-app default values are set using a plist file with the
`setDefaultsFromPlistFileName` method in this example, but you can also set
in-app default values inline using the other `setDefaults` methods of the
[`FIRRemoteConfig` class](https://firebase.google.com/docs/reference/ios/firebaseremoteconfig/api/reference/Classes/FIRRemoteConfig).

Then, you can override only those values that you need to change from the
Firebase console. This lets you use Remote Config for any default value that you
might want to override in the future, without the need to set all of those
values in the Firebase console.

### Fetch values from the Remote Config service 

When an app calls `fetchWithExpirationDuration:completionHandler`, updated
parameter values are fetched from the Remote Config service if either

* the last successful fetch occurred more than 12 hours ago, or
* a value less than 43200 (the number of seconds in 12 hours) is specified for
  `TimeInterval`.

Otherwise, cached parameter values are used.

Fetched values are cached locally, but not immediately activated. To activate
fetched values so that they take effect, call the `activateFetched` method. In
the quickstart sample app, you call this method from the UI by tapping
**Fetch & Activate Config**.

You can also create a Remote Config Setting to enable developer mode, but you
must remove this setting before distributing your app. Fetching Remote Config
data from the service is normally limited to a few requests per hour. By
enabling developer mode, you can make many more requests per hour, so you can
test your app with different Remote Config parameter values during development.

- To learn more about fetching data from Remote Config, see the Remote Config
  Frequently Asked Question (FAQ) on
  [fetching and activating parameter values](https://firebase.google.com/support/faq#remote-config-values).
- To learn about parameters and conditions that you can use to change the
  behavior and appearance of your app for segments of your userbase, see
  [Remote Config Parameters and Conditions](https://firebase.google.com/docs/remote-config/parameters).
- To learn more about the Remote Config API, see
  [Remote Config API Overview](https://firebase.google.com/docs/remote-config/api-overview).

Support
-------

- [Stack Overflow](https://stackoverflow.com/questions/tagged/firebase-remote-config)
- [Firebase Support](https://firebase.google.com/support/)

License
-------

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

