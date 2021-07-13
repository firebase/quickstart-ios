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
  @Published var colorScheme: ColorScheme

  init() {
    let value = RemoteConfig.remoteConfig()["color_scheme"].stringValue ?? "nil"
    colorScheme = ColorScheme(value)
    #if DEBUG
      NotificationCenter.default.addObserver(self,
                                             selector: #selector(printInstallationAuthToken),
                                             name: .InstallationIDDidChange,
                                             object: nil)
    #endif
  }

  #if DEBUG
    deinit { NotificationCenter.default.removeObserver(self) }
  #endif

  func updateFromRemoteConfig() {
    let remoteConfig = RemoteConfig.remoteConfig()
    let oldValue = remoteConfig["color_scheme"].stringValue ?? "nil"
    remoteConfig.fetchAndActivate { status, error in
      print("Fetch-and-activate completed with status: \(status.debugDescription)")
      if let error = error {
        print("Error fetching and activating config: \(error)")
      } else {
        let newValue = remoteConfig["color_scheme"].stringValue ?? "nil"
        if newValue != oldValue {
          print("Remote Config changed to: \(newValue)")
          DispatchQueue.main.async { self.colorScheme = ColorScheme(newValue) }
        } else {
          print("Remote Config did not change from: \(oldValue)")
        }
      }
    }
  }

  #if swift(>=5.5)
    @MainActor @available(iOS 15, *)
    func updateFromRemoteConfigAsync() async {
      let remoteConfig = RemoteConfig.remoteConfig()
      let oldValue = remoteConfig["color_scheme"].stringValue ?? "nil"
      do {
        let status = try await remoteConfig.fetchAndActivate()
        print("Fetch-and-activate completed with status: \(status.debugDescription)")
        let newValue = remoteConfig["color_scheme"].stringValue ?? "nil"
        if newValue != oldValue {
          print("Remote Config changed to: \(newValue)")
          colorScheme = ColorScheme(newValue)
        } else {
          print("Remote Config did not change from: \(oldValue)")
        }
      } catch {
        print("Error fetching and activating activating config: \(error)")
      }
    }
  #endif

  @objc func printInstallationAuthToken() {
    Installations.installations().authTokenForcingRefresh(true) { token, error in
      if let error = error {
        print("Error fetching token: \(error)")
      } else if let token = token {
        print("Installation auth token: \(token.authToken)")
      }
    }
  }
}

extension ColorScheme {
  init(_ value: String) {
    switch value {
    case "light":
      self = .light
    case "dark":
      self = .dark
    default:
      self = .light
      print("Unknown value, defaulting to ColorScheme.light")
    }
  }
}

extension RemoteConfigFetchAndActivateStatus {
  var debugDescription: String {
    switch self {
    case .error:
      return "error"
    case .successFetchedFromRemote:
      return "successFetchedFromRemote"
    case .successUsingPreFetchedData:
      return "successUsingPreFetchedData"
    @unknown default:
      return "unknown"
    }
  }
}
