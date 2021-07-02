//
//  Copyright 2021 Google LLC
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SwiftUI
import Firebase

class AppConfig: ObservableObject {
  @Published var colorScheme : ColorScheme
  init() {
    let value = RemoteConfig.remoteConfig()["color_scheme"].stringValue ?? "nil"
    colorScheme = value == "dark" ? .dark : .light
#if DEBUG
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(printInstallationAuthToken),
                                           name: .InstallationIDDidChange,
                                           object: nil)
#endif
  }
  deinit {
#if DEBUG
    NotificationCenter.default.removeObserver(self)
#endif
  }
  func updateFromRemoteConfig() {
    let remoteConfig = RemoteConfig.remoteConfig()
    remoteConfig.fetch(withExpirationDuration: 0) { (status, error) in
      print("Config fetch completed with status: \(status.debugDescription)")
      if let error = error {
        print("Error fetching config: \(error)")
      } else {
        remoteConfig.activate { changed, error in
          let value = remoteConfig["color_scheme"].stringValue ?? "nil"
          if changed {
            print("Remote Config changed to: \(value)")
            DispatchQueue.main.async {
              self.colorScheme = value == "dark" ? .dark : .light
            }
          } else {
            print("Remote Config did not change from: \(value)")
          }
        }
      }
    }
  }
  @objc func printInstallationAuthToken() {
    Installations.installations().authTokenForcingRefresh(true) { (token, error) in
      if let error = error {
        print("Error fetching token: \(error)")
      } else if let token = token {
        print("Installation auth token: \(token.authToken)")
      }
    }
  }
}