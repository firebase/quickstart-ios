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

import Foundation
import Firebase
import Reachability

class ReachabililtyHelper: NSObject {
  /**
   * Retrieve the locale information for the app.
   */
  func getLocale() -> String {
    return Locale.preferredLanguages[0]
  }

  /**
   * Retrieve the network status for the app.
   */
  func getNetworkStatus() -> String {
    guard let reachability = try? Reachability() else {
      return "unknown"
    }
    switch reachability.connection {
    case .wifi:
      return "wifi"
    case .cellular:
      return "cellular"
    case .unavailable:
      return "unavailable"
    case .none:
      // Duplicate of unavailable.
      return "unavailable"
    }
  }

  /**
   * Add a hook to update network status going forward.
   */
  func updateAndTrackNetworkStatus() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(reachabilityChanged(note:)),
                                           name: .reachabilityChanged,
                                           object: nil)
    do {
      let reachability = try Reachability()
      try reachability.startNotifier()
    } catch {
      print("Could not start reachability notifier: \(error)")
    }
  }

  @objc func reachabilityChanged(note: Notification) {
    Crashlytics.crashlytics().setCustomValue(getNetworkStatus(), forKey: "network_connection")
  }
}
