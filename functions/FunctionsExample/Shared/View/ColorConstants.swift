//
//  Copyright 2022 Google LLC
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
import SwiftUI

struct ColorConstants {
  #if os(iOS)
    static let textForegroundColor = Color(UIColor.secondaryLabel)
    static let roundRectangleFillColor = Color(.systemGray5)
    static let frameBackgroundColor = Color(.secondarySystemBackground)
  #elseif os(macOS)
    static let textForegroundColor = Color(NSColor.secondaryLabelColor)
    static let roundRectangleFillColor = Color(NSColor.systemGray)
    static let frameBackgroundColor = Color(NSColor.underPageBackgroundColor)
  #elseif os(tvOS)
    static let textForegroundColor = Color.secondary
    static let roundRectangleFillColor = Color.gray
    static let frameBackgroundColor = Color(.gray)
  #endif
}
