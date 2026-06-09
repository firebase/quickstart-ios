// Copyright 2026 Google LLC
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

import Foundation
import FoundationModels

extension Error {
    /// Returns true if this error indicates that required ML assets (like safety guardrails) 
    /// are missing from the device or simulator.
    public var isMLAssetUnavailable: Bool {
        // 1. Check for LanguageModelSession.GenerationError.assetsUnavailable
        if #available(iOS 26.0, *) {
            if let genError = self as? LanguageModelSession.GenerationError {
                if case .assetsUnavailable = genError {
                    return true
                }
            }
        }
        
        let nsError = self as NSError
        
        // 2. Check for the specific SensitiveContentAnalysisML error (Code 15)
        if nsError.domain == "com.apple.SensitiveContentAnalysisML" && nsError.code == 15 {
            return true
        }
        
        // 3. Check for underlying GenerativeFunctionsFoundation error (Code 1020000)
        // This is often found in the UserInfo of higher-level errors.
        if nsError.domain == "com.apple.GenerativeFunctionsFoundation.GenerativeError" && nsError.code == 1020000 {
            return true
        }
        
        // 4. Recursive check for underlying errors
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
            return underlying.isMLAssetUnavailable
        }
        
        return false
    }
    
    /// Returns a user-friendly message for ML asset errors, particularly for simulators.
    public var mlAssetErrorMessage: String? {
        guard isMLAssetUnavailable else { return nil }
        
        #if targetEnvironment(simulator)
        return """
        Apple Intelligence assets are missing in this simulator. 
        
        To fix this:
        1. Open Settings in the simulator.
        2. Go to Apple Intelligence & Siri.
        3. Toggle Apple Intelligence ON.
        4. Wait for assets to download (check the status in Settings).
        
        Alternatively, use a physical device with Apple Intelligence support.
        """
        #else
        return "Apple Intelligence assets are not yet ready on this device. Please ensure Apple Intelligence is enabled in Settings and that model assets have finished downloading."
        #endif
    }
}
