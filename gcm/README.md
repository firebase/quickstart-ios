Google Cloud Messaging Quickstart
=================================

The Google Cloud Messaging iOS Quickstart app demonstrates how to connect
an iOS app to GCM and how to receive messages.

Introduction
------------

TODO(ianbarber): instructions for EAP

Getting Started
---------------

TODO(ianbarber): setup instructions for eap
- Under **Project Settings > Notifications**, make sure to add a development APNs certificate (if you
want to use a production certificate, you need to change the value of kGGLInstanceIDAPNSServerTypeSandboxOption in the call to `tokenWithAuthorizedEntity` accordingly).
- Run the sample on your iOS device.
- Navigate to **Notifications**, and click **NEW MESSAGE**
- Fill in the message text and optionally the label; for target, you can choose one of:
    - **Topic**; if you choose this option, use `/topics/global` as your target;
    - **Single Device**; if you choose this option, insert the registration token that the sample app has printed in the XCode debug console as your target.
- Click **SEND MESSAGE**. A notification will be sent to your device.

Note: You need Swift 2.0 to run the Swift version of this quickstart.

Screenshots
-----------
![Screenshot](Screenshot/gcm-sample.png)

Support
-------

TODO(ianbarber): fill this if needed.

License
-------

Copyright 2015 Google, Inc.

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
