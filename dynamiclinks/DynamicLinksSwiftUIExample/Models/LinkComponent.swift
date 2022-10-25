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

struct LinkComponent: Identifiable, Equatable {
  let id: String
  let name: String
  let isRequired: Bool
  var isOptional: Bool { !isRequired }
  let requiredParameters: [LinkParameter]
  let optionalParameters: [LinkParameter]
  var allParameters: Set<LinkParameter> { Set(requiredParameters + optionalParameters) }

  init(id: String, name: String, isRequired: Bool = false, requiredParameters: [LinkParameter] = [],
       optionalParameters: [LinkParameter] = []) {
    self.id = id
    self.name = name
    self.isRequired = isRequired
    self.requiredParameters = requiredParameters
    self.optionalParameters = optionalParameters
  }
}

extension LinkComponent {
  static let all: [LinkComponent] = [
    .baseDynamicLink,
    .googleAnalytics,
    .iOS,
    .iTunes,
    .android,
    .social,
    .otherPlatform,
  ]

  static let baseDynamicLink = LinkComponent(
    id: "base-dynamic-link",
    name: "Base Dynamic Link",
    isRequired: true,
    requiredParameters: [.link]
  )
  static let googleAnalytics = LinkComponent(
    id: "google-analytics",
    name: "Google Analytics",
    requiredParameters: [LinkParameter.source, LinkParameter.medium, LinkParameter.campaign],
    optionalParameters: [LinkParameter.term, LinkParameter.content]
  )
  static let iOS = LinkComponent(
    id: "ios",
    name: "iOS",
    requiredParameters: [LinkParameter.bundleID],
    optionalParameters: [
      .iOSFallbackURL,
      .minimumiOSAppVersion,
      .customURLScheme,
      .iPadBundleID,
      .iPadFallbackURL,
      .appStoreID,
    ]
  )
  static let iTunes = LinkComponent(
    id: "itunes",
    name: "iTunes Connect Analytics",
    optionalParameters: [
      .iTunesAffiliateToken,
      .iTunesCampaignToken,
      .iTunesProviderToken,
    ]
  )
  static let android = LinkComponent(
    id: "android",
    name: "Android",
    requiredParameters: [.androidPackageName],
    optionalParameters: [.androidFallbackURL, .minimumAndroidAppVersion]
  )
  static let social = LinkComponent(
    id: "social",
    name: "Social Meta Tags",
    optionalParameters: [.title, .descriptionText, .imageURL]
  )
  static let otherPlatform = LinkComponent(
    id: "other-platform",
    name: "Other Platforms",
    optionalParameters: [.otherFallbackURL]
  )
}

extension LinkComponent {
  static var requiredLinkComponents: [LinkComponent] {
    LinkComponent.all.filter(\.isRequired)
  }

  static var optionalLinkComponents: [LinkComponent] {
    LinkComponent.all.filter(\.isRequired)
  }
}
