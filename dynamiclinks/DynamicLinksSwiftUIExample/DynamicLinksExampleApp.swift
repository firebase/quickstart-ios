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
  @State var alertPresented: Bool = false
  @State var alertMessage: String = "URL: empty"
  @State var receivedLinkModel: ReceivedLinkModel?

  var body: some Scene {
    WindowGroup {
      NavigationView {
        LinkConfigurationView()
      }.environmentObject(model)
        .onOpenURL { url in
          let dynamicLinks = DynamicLinks.dynamicLinks()
          if dynamicLinks.shouldHandleDynamicLink(fromCustomSchemeURL: url) {
            print("The URL \(url) has an FDL Custom Scheme; should be handled.")
            if let dynamicLink = dynamicLinks.dynamicLink(fromCustomSchemeURL: url) {
              receivedLinkModel = ReceivedLinkModel(receivedURL: url, dynamicLink: dynamicLink)
            } else {
              print("The URL \(url) is not an FDL Dynamic Link.")
            }
          } else {
            print("The URL \(url) does not have an FDL Custom Scheme; should be handled as Universal URL.")
            Task {
              if let dynamicLink: DynamicLink = await handleLink(url) {
                receivedLinkModel = ReceivedLinkModel(receivedURL: url, dynamicLink: dynamicLink)
              }
            }
          }
        }
        .sheet(item: $receivedLinkModel, content: { LinkReceivedView(receivedLinkModel: $0) })
    }.handlesExternalEvents(matching: ["*"])
  }

  func handleLink(_ url: URL) async -> DynamicLink? {
    await withCheckedContinuation { continuation in
      handleLink(url) { dynamicLink, error in
        // TODO: Handle error
        continuation.resume(returning: dynamicLink)
      }
    }
  }

  func handleLink(_ url: URL, completion: @escaping (DynamicLink?, Error?) -> Void) {
    guard DynamicLinks.dynamicLinks().handleUniversalLink(url, completion: { dynamicLink, error in
      completion(dynamicLink, error)
      return
    }) else {
      return
    }
  }
}
