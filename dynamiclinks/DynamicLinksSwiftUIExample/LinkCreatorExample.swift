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

struct LinkCreatorExample {
  enum LinkGenerationError: Error {
    case missingLinkTarget
    case missingDomainURIPrefix
    case invalidLinkPayload
    case invalidLinkParameters
    case linkGenerationFailed
  }

  let parameterStates: [LinkParameter.ID: LinkParameterState]

  func generateDynamicLinkComponents() throws -> DynamicLinkComponents {
    // general link params
    guard let linkURL = URL(string: parameterStates[LinkParameter.link.id]?.value ?? "") else {
      throw LinkGenerationError.missingLinkTarget
    }

    guard let domainURIPrefix: String = parameterStates[LinkParameter.domainURIPrefix.id]?.value
    else {
      throw LinkGenerationError.missingDomainURIPrefix
    }

    guard let components = DynamicLinkComponents(
      link: linkURL,
      domainURIPrefix: domainURIPrefix
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
    guard let source = parameterStates[LinkParameter.source.id]?.value,
      let medium = parameterStates[LinkParameter.medium.id]?.value,
      let campaign = parameterStates[LinkParameter.campaign.id]?.value else { return nil }

    let analyticsParams = DynamicLinkGoogleAnalyticsParameters(
      source: source,
      medium: medium,
      campaign: campaign
    )
    analyticsParams.term = parameterStates[LinkParameter.term.id]?.value
    analyticsParams.content = parameterStates[LinkParameter.content.id]?.value

    return analyticsParams
  }

  func generateiOSParameters() -> DynamicLinkIOSParameters? {
    guard let bundleID = parameterStates[LinkParameter.bundleID.id]?.value else {
      return nil
    }

    let iOSParams = DynamicLinkIOSParameters(bundleID: bundleID)
    iOSParams.fallbackURL = parameterStates[LinkParameter.iOSFallbackURL.id]
      .flatMap { URL(string: $0.value) }
    iOSParams.minimumAppVersion = parameterStates[LinkParameter.minimumiOSAppVersion.id]?.value
    iOSParams.customScheme = parameterStates[LinkParameter.customURLScheme.id]?.value
    iOSParams.iPadBundleID = parameterStates[LinkParameter.iPadBundleID.id]?.value
    iOSParams.iPadFallbackURL = parameterStates[LinkParameter.iPadFallbackURL.id]
      .flatMap { URL(string: $0.value) }
    iOSParams.appStoreID = parameterStates[LinkParameter.appStoreID.id]?.value

    return iOSParams
  }

  private func generateiTunesConnectParameters() -> DynamicLinkItunesConnectAnalyticsParameters {
    let iTunesConnectParams = DynamicLinkItunesConnectAnalyticsParameters()
    iTunesConnectParams.affiliateToken = parameterStates[LinkParameter.iTunesAffiliateToken.id]?
      .value
    iTunesConnectParams.campaignToken = parameterStates[LinkParameter.iTunesCampaignToken.id]?.value
    iTunesConnectParams.providerToken = parameterStates[LinkParameter.iTunesProviderToken.id]?.value

    return iTunesConnectParams
  }

  private func generateAndroidParameters() -> DynamicLinkAndroidParameters? {
    guard let packageName = parameterStates[LinkParameter.androidPackageName.id]?.value else {
      return nil
    }

    // Android params
    let androidParams = DynamicLinkAndroidParameters(packageName: packageName)
    androidParams.fallbackURL = parameterStates[LinkParameter.androidFallbackURL.id]
      .flatMap { URL(string: $0.value) }
    androidParams.minimumVersion = parameterStates[LinkParameter.minimumAndroidAppVersion.id]
      .flatMap { Int($0.value) } ?? 0

    return androidParams
  }

  private func generateSocialMetaTagParameters() -> DynamicLinkSocialMetaTagParameters {
    let socialParams = DynamicLinkSocialMetaTagParameters()
    socialParams.title = parameterStates[LinkParameter.title.id]?.value
    socialParams.descriptionText = parameterStates[LinkParameter.descriptionText.id]?.value
    socialParams.imageURL = parameterStates[LinkParameter.imageURL.id]
      .flatMap { URL(string: $0.value) }

    return socialParams
  }

  private func generateOtherPlatformParameters() -> DynamicLinkOtherPlatformParameters {
    let otherPlatformParams = DynamicLinkOtherPlatformParameters()
    otherPlatformParams.fallbackUrl = parameterStates[LinkParameter.otherFallbackURL.id]
      .flatMap { URL(string: $0.value) }

    return otherPlatformParams
  }
}
