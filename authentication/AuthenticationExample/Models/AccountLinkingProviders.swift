// Copyright 2020 Google LLC
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

/// Firebase Auth supported identity providers and other methods of authentication
enum AccountLinkingProvider: String, CaseIterable {
  case google = "Google"
  case apple = "Apple"
  case twitter = "Twitter"
  case microsoft = "Microsoft"
  case gitHub = "GitHub"
  case yahoo = "Yahoo"
  case facebook = "Facebook"
  case emailPassword = "Email & Password Login"
  case passwordless = "Email Link/Passwordless"
  case phoneNumber = "Phone Number"
  case anonymous = "Anonymous Authentication"
  case custom = "Custom Auth System"

  var id: String { rawValue.lowercased().appending(".com") }
}

// MARK: DataSourceProvidable

extension AccountLinkingProvider {
  private static var providers: [AccountLinkingProvider] {
    self.allCases
  }

  static var providerSection: Section {
    var providers = self.providers.map { Item(title: $0.rawValue) }
    
    let image = UIImage(named: "firebaseIcon")
    let item = Item(title: emailPassword.rawValue, image: image)
    providers.append(item)
    
    let lockSymbol = UIImage.systemImage("lock.slash.fill", tintColor: .systemOrange)
    let phoneSymbol = UIImage.systemImage("phone.fill", tintColor: .systemOrange)
    let anonSymbol = UIImage.systemImage("questionmark.circle.fill", tintColor: .systemOrange)
    let shieldSymbol = UIImage.systemImage("lock.shield.fill", tintColor: .systemOrange)

    let otherOptions = [
      Item(title: passwordless.rawValue, image: lockSymbol),
      Item(title: phoneNumber.rawValue, image: phoneSymbol),
      Item(title: anonymous.rawValue, image: anonSymbol),
      Item(title: custom.rawValue, image: shieldSymbol),
    ]
    providers.append(contentsOf: otherOptions)
    
    let header = "Link with accounts with..."
    let footer = "Accounts marked with a Choose a login flow from one of the identity providers above."
    return Section(headerDescription: header, footerDescription: footer, items: providers)
  }


  static var sections: [Section] {
    [providerSection]
  }

  var sections: [Section] { AccountLinkingProvider.sections }
}
