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

import SwiftUI

class ScreenDimensions {
  #if os(iOS) || os(tvOS)
    static var width: CGFloat = UIScreen.main.bounds.size.width
    static var height: CGFloat = UIScreen.main.bounds.size.height
  #elseif os(macOS)
    static var width: CGFloat = NSScreen.main?.visibleFrame.size.width ?? 0
    static var height: CGFloat = NSScreen.main?.visibleFrame.size.height ?? 0
  #endif
}
