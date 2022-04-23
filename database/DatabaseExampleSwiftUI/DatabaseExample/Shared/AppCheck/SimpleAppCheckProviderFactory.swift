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

class SimpleAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
  func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
    #if targetEnvironment(simulator)
      // App Attest is not available on simulators.
      // Use a debug provider.
      let provider = AppCheckDebugProvider(app: app)

      // Print only locally generated token to avoid a valid token leak on CI.
      print("Firebase App Check debug token: \(provider?.localDebugToken() ?? "")")

      return provider
    #else
      if #available(iOS 14.0, *) {
        // Use App Attest provider on real devices.
        return MyCustomAppCheckProvider(app: app)
      } else {
        return DeviceCheckProvider(app: app)
      }
    #endif
  }
}
