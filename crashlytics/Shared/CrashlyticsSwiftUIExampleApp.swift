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
import FirebaseCore
import FirebaseCrashlytics

@main
struct CrashlyticsSwiftUIExampleApp: App {
  private var crashlyticsReference = Crashlytics.crashlytics()
  #if !os(watchOS)
    let reachabilityHelper = ReachabililtyHelper()
  #endif

  func setUserInfo() {
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

  func setCustomValues() {
    crashlyticsReference.setCustomValue(42, forKey: "MeaningOfLife")
    crashlyticsReference.setCustomValue("Test value", forKey: "last_UI_action")
    // Reachability is not compatible with watchOS
    #if !os(watchOS)
      let customKeysObject = [
        "locale": reachabilityHelper.getLocale(),
        "network_connection": reachabilityHelper.getNetworkStatus(),
      ] as [String: Any]
      crashlyticsReference.setCustomKeysAndValues(customKeysObject)
      reachabilityHelper.updateAndTrackNetworkStatus()
    #endif
    Crashlytics.crashlytics().setUserID("123456789")
  }

  init() {
    FirebaseApp.configure()
    Crashlytics.crashlytics().log("App loaded")
    setCustomValues()
    setUserInfo()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
