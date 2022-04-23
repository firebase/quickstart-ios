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
import DeviceCheck

import Firebase

/// The App Check provider that uses Firebase Remote Config to either forward 
/// Firebase App Check token request to the standard AppAttestProvider fail 
/// to skip attestation. The attestation provider also logs Analytics events to
/// track if App Attest API is available on a device and if attestation 
/// succeeded or failed. The main motivation to use the custom App Check 
/// provider is to gradually enable App Attest attestation to avoid throttling
/// form Apple backend. Another reason is tracking additional metrics with 
/// Firebase Analytics.
/// NOTE: This is an example and may require additional optimizations to ensure the best performance in a production app, e.g. you may want to avoid fetching and activating Remote Config as a part of attestation and prefer to do it separately to avoid additional latency of the attestation process.
class MyCustomAppCheckProvider: NSObject, AppCheckProvider {
  let firebaseApp: FirebaseApp

  init(firebaseApp: FirebaseApp) {
    self.firebaseApp = firebaseApp

    super.init()

    // Log Analytics event if App Attest is available.
    logAppAttestAvailability()

    #if DEBUG
      // Print FIS Auth token for
      printFISToken()
    #endif
  }

  private lazy var appAttestProvider: AppAttestProvider? = {
    AppAttestProvider(app: self.firebaseApp)
  }()

  func getToken(completion handler: @escaping (AppCheckToken?, Error?) -> Void) {
    // Fetch App Attest flag from remote config.
    let remoteConfig = RemoteConfig.remoteConfig(app: firebaseApp)
    remoteConfig.fetchAndActivate { remoteConfigStatus, error in
      // Get App Attest flag value.
      let appAttestEnabled = remoteConfig[Constants.appAttestRemoteConfigFlagName].boolValue

      guard appAttestEnabled else {
        // Skip attestation if App Attest is disabled. Another attestation method like DeviceCheck may be used instead of just skipping.
        handler(nil, ProviderError.appAttestIsDisabled)
        return
      }

      // Try to obtain App Attest provider instance and fail if cannot.
      guard let appAttestProvider = self.appAttestProvider else {
        handler(nil, ProviderError.appAttestIsUnavailable)
        return
      }

      appAttestProvider.getToken(completion: handler)

      // If App Attest is enabled for the app instance then forward the Firebase App Check token request to App Attest provider.
      appAttestProvider.getToken { token, error in
        // Log an analytics event to track attestation success rate and make a decision if App Attest rollout should proceed.
        let appAttestEvent = (token != nil && error == nil) ? Constants
          .appAttestAvailableSuccessEventName : Constants.appAttestAvailableFailureEventName
        Analytics.logEvent(appAttestEvent, parameters: nil)

        // Pass the result to the handler.
        handler(token, error)
      }
    }
  }

  /// Logs an Analytics event if App Attest is available. It will be used as a trigger for the App Attest rollout A/B testing experiment.
  private func logAppAttestAvailability() {
    if DCAppAttestService.shared.isSupported {
      Analytics.logEvent(Constants.appAttestAvailableEventName, parameters: nil)
    }
  }

  /// Retrieves and prints a Firebase Installations Service (FIS) auth token.
  /// The token can be used to assign a particular A/B testing experiment variant to a test device.
  private func printFISToken() {
    Installations.installations(app: firebaseApp).authToken { tokenResult, error in
      print("FIS auth token: \(String(describing: tokenResult?.authToken))")
    }
  }

  // A factory class to connect the custom provider to Firebase App Check.
  class Factory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
      return MyCustomAppCheckProvider(firebaseApp: app)
    }
  }
}

extension MyCustomAppCheckProvider {
  /// The provider errors enum.
  enum ProviderError: Error {
    case appAttestIsDisabled
    case appAttestIsUnavailable
  }

  /// Constants.
  enum Constants {
    /// Remote Config flag name for enabling/disabling App Attest.
    static let appAttestRemoteConfigFlagName = "AppAttestEnabled"

    /// Analytics event name to log if App Attest is available on the device.
    static let appAttestAvailableEventName = "AppAttestAvailable"
    /// Analytics event name to log when App Attest attestation succeeds.
    static let appAttestAvailableSuccessEventName = "AppAttestSuccess"
    /// Analytics event name to log when App Attest attestation fails.
    static let appAttestAvailableFailureEventName = "AppAttestFailure"
  }
}
