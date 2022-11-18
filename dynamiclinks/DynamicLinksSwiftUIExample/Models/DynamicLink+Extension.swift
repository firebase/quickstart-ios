// Copyright 2022 Google LLC
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
import FirebaseDynamicLinks

protocol BaseDynamicLink {
  var url: URL? { get }
  var matchType: DLMatchType { get }
  var utmParametersDictionary: [String: Any] { get }
  var minimumAppVersion: String? { get }
}

extension DynamicLink: BaseDynamicLink {}

struct MutableDynamicLink: BaseDynamicLink {
  var url: URL? = nil
  var matchType: DLMatchType = .default
  var utmParametersDictionary: [String: Any] = [:]
  var minimumAppVersion: String? = nil
}

extension DLMatchType {
  var name: String {
    switch self {
    case .unique:
      return "Unique"
    case .default:
      return "Default"
    case .weak:
      return "Weak"
    case .none:
      return "None"
      @unknown default:
      return "Unknown"
    }
  }
}
