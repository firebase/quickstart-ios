//
//  Copyright (c) 2021 Google Inc.
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

import Foundation
import Firebase


class MyCustomAppCheckProvider: NSObject, AppCheckProvider {
  enum ProviderError: Error {
    case appAttestIsDisabled
    case appAttestIsUnavailable
  }

  let appAttestRemoteConfigFlagName = "app-attest-enabled"

  let firebaseApp: FirebaseApp

  init(firebaseApp: FirebaseApp) {
    self.firebaseApp = firebaseApp
  }

  private var _appAttestProvider: AppAttestProvider?
  private var appAttestProvider: AppAttestProvider? {
    if let appAttestProvider = _appAttestProvider {
      return appAttestProvider
    } else {
      _appAttestProvider = AppAttestProvider(app: self.firebaseApp)
      return _appAttestProvider
    }
  }

  func getToken(completion handler: @escaping (AppCheckToken?, Error?) -> Void) {
    // Fetch App Attest flag from remote config.
    let remoteConfig = RemoteConfig.remoteConfig(app:firebaseApp)

    let appAttestEnabled = remoteConfig[appAttestRemoteConfigFlagName].boolValue

    guard appAttestEnabled else {
      handler(nil, ProviderError.appAttestIsDisabled)
      return
    }

    // If App Attest is enabled for the app instance then forward the Firebase App Check token request to App Attest provider.
    guard let appAttestProvider = self.appAttestProvider else {
      handler(nil, ProviderError.appAttestIsUnavailable)
      return
    }

    appAttestProvider.getToken(completion: handler)
  }

  class Factory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
      return MyCustomAppCheckProvider(firebaseApp: app)
    }
  }
}
