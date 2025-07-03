// Copyright 2025 Google LLC
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

import SwiftUI

extension Color {
  static let appBackground = Color(uiColor: .systemBackground)
  static let inputBackground = Color(uiColor: .systemGray5)
  static let userPromptBackground = Color(
    uiColor: UIColor(
      light: UIColor.cyan.withAlphaComponent(0.2),
      dark: UIColor.cyan.withAlphaComponent(0.4)
    )
  )
  static let userPromptText = Color(uiColor: UIColor(light: .black, dark: .white))
  static let modelResponseBackground = Color(uiColor: .systemGray6)
}

extension UIColor {
  /// Custom initializer to handle different colors for light and dark mode.
  convenience init(light: UIColor, dark: UIColor) {
    self.init { traitCollection in
      traitCollection.userInterfaceStyle == .dark ? dark : light
    }
  }
}
