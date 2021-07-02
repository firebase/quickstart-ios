//
// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI
import Firebase

@main
struct CrashlyticsSwiftUIExampleApp: App {
  let reachabilityHelper = ReachabililtyHelper()

  init() {
    FirebaseApp.configure()
    Crashlytics.crashlytics().log("App loaded")

    Crashlytics.crashlytics().setCustomValue(42, forKey: "MeaningOfLife")
    Crashlytics.crashlytics().setCustomValue("Test value", forKey: "last_UI_action")

    let customKeysObject = [
      "locale": reachabilityHelper.getLocale(),
      "network_connection": reachabilityHelper.getNetworkStatus(),
    ] as [String: Any]
    Crashlytics.crashlytics().setCustomKeysAndValues(customKeysObject)
    reachabilityHelper.updateAndTrackNetworkStatus()
    Crashlytics.crashlytics().setUserID("123456789")

    let userInfo = [
      NSLocalizedDescriptionKey: NSLocalizedString("The request failed.", comment: ""),
      NSLocalizedFailureReasonErrorKey: NSLocalizedString(
        "The response returned a 404.",
        comment: ""
      ),
      NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(
        "Does this page exist?",
        comment: ""
      ),
      "ProductID": "123456",
      "UserID": "Jane Smith",
    ]
    let error = NSError(domain: NSURLErrorDomain, code: -1001, userInfo: userInfo)
    Crashlytics.crashlytics().record(error: error)
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
