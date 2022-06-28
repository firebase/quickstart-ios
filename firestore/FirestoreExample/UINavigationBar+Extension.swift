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

import UIKit

extension UINavigationBar {
  static let firebaseBlue =
    UIColor(red: 0x3D / 0xFF, green: 0x5A / 0xFF, blue: 0xFE / 0xFF, alpha: 1.0)
  static let firebaseTitleTextAttributes =
    [NSAttributedString.Key.foregroundColor: UIColor.white]

  @available(iOS 13.0, *)
  var firebaseNavigationBarAppearance: UINavigationBarAppearance {
    let navBarAppearance = UINavigationBarAppearance()
    navBarAppearance.configureWithOpaqueBackground()
    navBarAppearance.backgroundColor = UINavigationBar.firebaseBlue
    navBarAppearance.titleTextAttributes = UINavigationBar.firebaseTitleTextAttributes
    return navBarAppearance
  }

  @available(iOS 13.0, *)
  func applyAppearance(_ appearance: UINavigationBarAppearance) {
    standardAppearance = appearance
    compactAppearance = appearance
    scrollEdgeAppearance = appearance
    if #available(iOS 15.0, *) {
      compactScrollEdgeAppearance = appearance
    }
  }

  func applyFirebaseAppearance() {
    barTintColor = UINavigationBar.firebaseBlue
    isTranslucent = false
    titleTextAttributes = UINavigationBar.firebaseTitleTextAttributes

    if #available(iOS 13.0, *) {
      applyAppearance(firebaseNavigationBarAppearance)
    }
  }
}
