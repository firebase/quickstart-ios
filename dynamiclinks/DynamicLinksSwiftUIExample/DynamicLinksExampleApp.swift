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
import SwiftUI
// [START import]
import FirebaseCore
import FirebaseDynamicLinks
// [END import]

class AppDelegate: NSObject, UIApplicationDelegate {
  // The default URL scheme for this example app.
  let customURLScheme = "dlscheme"

  // [START didfinishlaunching]
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication
                     .LaunchOptionsKey: Any]? = nil) -> Bool {
    // Set deepLinkURLScheme to the custom URL scheme defined in your Xcode project.
    if let options = FirebaseOptions.defaultOptions() {
      options.deepLinkURLScheme = customURLScheme
    }

    FirebaseApp.configure()

    return true
  }

  // [END didfinishlaunching]
}

@main
struct DynamicLinksExampleApp: App {
  static let domainURIPrefix = "YOUR_DOMAIN_URI_PREFIX"

  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @StateObject var model = LinkModel()
  @State var receivedLinkModels: [ReceivedLinkModel] = []
  @State var receivedLinkModel: ReceivedLinkModel?

  var body: some Scene {
    WindowGroup {
      NavigationView {
        LinkConfigurationView()
      }.environmentObject(model)
        // [START openurl]
        .onOpenURL { url in
          Task {
            // Handle the deep link. For example, show the deep-linked content or
            // apply a promotional offer to the user's account.
            var dynamicLink: DynamicLink?
            var extractError: Error?
            do {
              dynamicLink = try await extractDynamicLink(fromURL: url)
            } catch {
              extractError = error
            }

            // [START_EXCLUDE]
            // In this sample we just add the link to a list to be shown.
            let model = ReceivedLinkModel(
              receivedURL: url,
              dynamicLink: dynamicLink,
              error: extractError
            )

            await MainActor.run {
              if receivedLinkModel == nil {
                receivedLinkModel = model
              } else {
                receivedLinkModels.append(model)
              }
            }
            // [END_EXCLUDE]
          }
        }
        // [END openurl]

        // Show received links as sheets, displaying them one at a time.
        .sheet(item: $receivedLinkModel, onDismiss: {
          if receivedLinkModels.first != nil {
            receivedLinkModel = receivedLinkModels.removeFirst()
          } else {
            receivedLinkModel = nil
          }
        }) { LinkReceivedView(receivedLinkModel: $0) }
    }.handlesExternalEvents(matching: ["*"])
  }

  func extractDynamicLink(fromURL url: URL) async throws -> DynamicLink {
    let dynamicLinks = DynamicLinks.dynamicLinks()
    let longURL: URL = dynamicLinks.matchesShortLinkFormat(url) ? try await dynamicLinks
      .resolveShortLink(url) : url

    if let dynamicLink = extractDynamicLink(fromCustomSchemeURL: longURL) {
      return dynamicLink
    }

    return try await DynamicLinks.dynamicLinks().dynamicLink(fromUniversalLink: longURL)
  }

  func extractDynamicLink(fromCustomSchemeURL url: URL) -> DynamicLink? {
    guard DynamicLinks.dynamicLinks().shouldHandleDynamicLink(fromCustomSchemeURL: url)
    else { return nil }
    guard let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) else {
      return nil
    }

    return dynamicLink
  }
}
