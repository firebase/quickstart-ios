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

struct LinkParameter: Identifiable, Equatable, Hashable {
  let id: String
  let name: String
}

extension LinkParameter {
  static let all: [LinkParameter] = [
    .link,
    .title,
    .descriptionText,
    .imageURL,
    .otherFallbackURL,
    .source,
    .medium,
    .campaign,
    .term,
    .content,
    .bundleID,
    .iOSFallbackURL,
    .minimumiOSAppVersion,
    .customURLScheme,
    .iPadBundleID,
    .iPadFallbackURL,
    .appStoreID,
    .iTunesAffiliateToken,
    .iTunesCampaignToken,
    .iTunesProviderToken,
    .androidPackageName,
    .androidFallbackURL,
    .minimumAndroidAppVersion,
  ]

  static let link = LinkParameter(id: "link-target", name: "Link Target")
  static let source = LinkParameter(id: "source", name: "Source")
  static let medium = LinkParameter(id: "medium", name: "Medium")
  static let campaign = LinkParameter(id: "campaign", name: "Campaign")
  static let term = LinkParameter(id: "term", name: "Term")
  static let content = LinkParameter(id: "content", name: "Content")
  static let bundleID = LinkParameter(id: "bundle-id", name: "App Bundle ID")
  static let iOSFallbackURL = LinkParameter(id: "ios-fallback-url", name: "Fallback URL")
  static let minimumiOSAppVersion = LinkParameter(
    id: "minimum-ios-app-version",
    name: "Minimum App Version"
  )
  static let customURLScheme = LinkParameter(id: "custom-url-scheme", name: "Custom URL Scheme")
  static let iPadBundleID = LinkParameter(id: "ipad-bundle-id", name: "iPad Bundle ID")
  static let iPadFallbackURL = LinkParameter(id: "ipad-fallback-url", name: "iPad Fallback URL")
  static let appStoreID = LinkParameter(id: "app-store-id", name: "App Store ID")
  static let iTunesAffiliateToken = LinkParameter(
    id: "itunes-affiliate-token",
    name: "Affiliate Token"
  )
  static let iTunesCampaignToken = LinkParameter(
    id: "itunes-campaign-token",
    name: "Campaign Token"
  )
  static let iTunesProviderToken = LinkParameter(
    id: "itunes-provider-token",
    name: "Provider Token"
  )
  static let androidPackageName = LinkParameter(id: "android-package-name", name: "Package Name")
  static let androidFallbackURL = LinkParameter(id: "android-fallback-url", name: "Fallback URL")
  static let minimumAndroidAppVersion = LinkParameter(
    id: "minimum-android-app-version",
    name: "Minimum App Version"
  )
  static let title = LinkParameter(id: "title", name: "Title")
  static let descriptionText = LinkParameter(id: "description-text", name: "Description Text")
  static let imageURL = LinkParameter(id: "image-url", name: "Image URL")
  static let otherFallbackURL = LinkParameter(
    id: "other-platform-fallback-url",
    name: "Other Platform Fallback URL"
  )
}
