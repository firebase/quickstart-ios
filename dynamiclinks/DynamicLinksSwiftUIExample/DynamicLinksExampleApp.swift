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

import SwiftUI
import FirebaseCore
import FirebaseDynamicLinks

@main
struct DynamicLinksExampleApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @StateObject var model = LinkModel()
  @State var receivedLinkModels: [ReceivedLinkModel] = []
  @State var receivedLinkModel: ReceivedLinkModel?

  var body: some Scene {
    WindowGroup {
      NavigationView {
        LinkConfigurationView()
      }.environmentObject(model)
        .onOpenURL { url in
          Task {
            var dynamicLink: DynamicLink?
            var extractError: Error?
            do {
              dynamicLink = try await extractDynamicLink(fromURL: url)
            } catch {
              extractError = error
            }

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
          }
        }
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
