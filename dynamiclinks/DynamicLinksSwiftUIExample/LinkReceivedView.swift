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
import FirebaseDynamicLinks

struct LinkReceivedView: View {
  let receivedLinkModel: ReceivedLinkModel

  var body: some View {
    Form {
      Section(header: Text("Received URL")) {
        if let linkURL = receivedLinkModel.receivedURL {
          HStack {
            Label("URL", systemImage: "link")
            Text(linkURL.absoluteString).font(.system(.body, design: .monospaced))
          }
        }
      }
      if let dynamicLink = receivedLinkModel.dynamicLink, let linkURL = dynamicLink.url {
        Section(header: Text("Dynamic Link")) {
          LazyVGrid(columns: [
            GridItem(.flexible(minimum: 50.0, maximum: .infinity),
                     alignment: .init(horizontal: .trailing, vertical: .center)),
            GridItem(
              .flexible(minimum: 50.0, maximum: .infinity),
              alignment: .init(horizontal: .leading, vertical: .center)
            ),
          ]) {
            Text("URL").multilineTextAlignment(.trailing)
            Link(
              destination: linkURL,
              label: {
                Label(linkURL.absoluteString, systemImage: "link").labelStyle(.titleOnly)
                  .multilineTextAlignment(.leading)
              }
            )
            Text("Match Confidence").multilineTextAlignment(.trailing)
            Text(dynamicLink.matchType.name).multilineTextAlignment(.leading)
            Text("UTM Parameters").multilineTextAlignment(.trailing)
            Text(dynamicLink.utmParametersDictionary.description).multilineTextAlignment(.leading)
            Text("Minimum App Version").multilineTextAlignment(.trailing)
            Text(dynamicLink.minimumAppVersion ?? "N/A").multilineTextAlignment(.leading)
          }
        }
      }
      if let error = receivedLinkModel.error {
        Section(header: Text("Error")) {
          Text(error.localizedDescription)
        }
      }
    }
  }
}

struct LinkReceivedView_Previews: PreviewProvider {
  static let linkURL = "https://firebase.google.com"

  static var previews: some View {
    LinkReceivedView(receivedLinkModel: ReceivedLinkModel(
      receivedURL: URL(string: "https://firebase.page.link?link=\(linkURL)"),
      dynamicLink: MutableDynamicLink(
        url: URL(string: linkURL),
        matchType: .unique
      ), error: nil
    )).previewDisplayName("Received Dynamic Link")

    LinkReceivedView(receivedLinkModel: ReceivedLinkModel(
      receivedURL: URL(string: linkURL),
      dynamicLink: nil, error: DynamicLinkError.previewError
    )).previewDisplayName("Dynamic Link Error")
  }
}

private enum DynamicLinkError: Error {
  case previewError
}

extension DynamicLinkError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .previewError:
      return "The received URL is not a Dynamic Link."
    }
  }
}
