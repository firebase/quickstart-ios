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
import FirebaseCore
import FirebaseDynamicLinks

struct LinkCreatorExample {
  enum LinkGenerationError: Error {
    case missingLinkTarget
    case missingDomainURIPrefix
    case invalidLinkPayload
    case invalidLinkParameters
    case linkGenerationFailed
  }

  let parameterStates: [LinkParameter.ID: LinkParameterState]

  // [START buildFDLLink]
  func generateDynamicLinkComponents() throws -> DynamicLinkComponents {
    if DynamicLinksExampleApp.domainURIPrefix == "YOUR_DOMAIN_URI_PREFIX" {
      fatalError("Please update the domainURIPrefix constant in DynamicLinksExampleApp to match" +
        " the Domain URI Prefix set in the Firebase Console.")
    }

    // general link params
    guard let linkURL = parameterStates.value(parameter: .link).flatMap(URL.init) else {
      throw LinkGenerationError.missingLinkTarget
    }

    guard let components = DynamicLinkComponents(
      link: linkURL,
      domainURIPrefix: DynamicLinksExampleApp.domainURIPrefix
    ) else { throw LinkGenerationError.invalidLinkParameters }

    components.analyticsParameters = generateAnalyticsParameters()
    components.iOSParameters = generateiOSParameters()
    components.iTunesConnectParameters = generateiTunesConnectParameters()
    components.androidParameters = generateAndroidParameters()
    components.socialMetaTagParameters = generateSocialMetaTagParameters()
    components.otherPlatformParameters = generateOtherPlatformParameters()

    guard components.url != nil else { throw LinkGenerationError.linkGenerationFailed }

    return components
  }

  func generateAnalyticsParameters() -> DynamicLinkGoogleAnalyticsParameters? {
    guard let source = parameterStates.value(parameter: .source),
      let medium = parameterStates.value(parameter: .medium),
      let campaign = parameterStates.value(parameter: .campaign) else { return nil }

    let analyticsParams = DynamicLinkGoogleAnalyticsParameters(
      source: source,
      medium: medium,
      campaign: campaign
    )
    analyticsParams.term = parameterStates.value(parameter: .term)
    analyticsParams.content = parameterStates.value(parameter: .content)

    return analyticsParams
  }

  func generateiOSParameters() -> DynamicLinkIOSParameters? {
    guard let bundleID = parameterStates.value(parameter: .bundleID) else {
      return nil
    }

    let iOSParams = DynamicLinkIOSParameters(bundleID: bundleID)
    iOSParams.fallbackURL = parameterStates.value(parameter: .iOSFallbackURL)
      .flatMap(URL.init)
    iOSParams.minimumAppVersion = parameterStates.value(parameter: .minimumiOSAppVersion)
    iOSParams.customScheme = parameterStates.value(parameter: .customURLScheme)
    iOSParams.iPadBundleID = parameterStates.value(parameter: .iPadBundleID)
    iOSParams.iPadFallbackURL = parameterStates.value(parameter: .iPadFallbackURL)
      .flatMap(URL.init)
    iOSParams.appStoreID = parameterStates.value(parameter: .appStoreID)

    return iOSParams
  }

  private func generateiTunesConnectParameters() -> DynamicLinkItunesConnectAnalyticsParameters {
    let iTunesConnectParams = DynamicLinkItunesConnectAnalyticsParameters()
    iTunesConnectParams.affiliateToken = parameterStates.value(parameter: .iTunesAffiliateToken)
    iTunesConnectParams.campaignToken = parameterStates.value(parameter: .iTunesCampaignToken)
    iTunesConnectParams.providerToken = parameterStates.value(parameter: .iTunesProviderToken)

    return iTunesConnectParams
  }

  private func generateAndroidParameters() -> DynamicLinkAndroidParameters? {
    guard let packageName = parameterStates.value(parameter: .androidPackageName) else {
      return nil
    }

    // Android params
    let androidParams = DynamicLinkAndroidParameters(packageName: packageName)
    androidParams.fallbackURL = parameterStates.value(parameter: .androidFallbackURL)
      .flatMap(URL.init)
    if let minimumVersion = parameterStates.value(parameter: .minimumAndroidAppVersion)
      .flatMap(Int.init) {
      androidParams.minimumVersion = minimumVersion
    }

    return androidParams
  }

  private func generateSocialMetaTagParameters() -> DynamicLinkSocialMetaTagParameters {
    let socialParams = DynamicLinkSocialMetaTagParameters()
    socialParams.title = parameterStates.value(parameter: .title)
    socialParams.descriptionText = parameterStates.value(parameter: .descriptionText)
    socialParams.imageURL = parameterStates.value(parameter: .imageURL)
      .flatMap(URL.init)

    return socialParams
  }

  private func generateOtherPlatformParameters() -> DynamicLinkOtherPlatformParameters {
    let otherPlatformParams = DynamicLinkOtherPlatformParameters()
    otherPlatformParams.fallbackUrl = parameterStates.value(parameter: .otherFallbackURL)
      .flatMap(URL.init)

    return otherPlatformParams
  }

  // [END buildFDLLink]
}
