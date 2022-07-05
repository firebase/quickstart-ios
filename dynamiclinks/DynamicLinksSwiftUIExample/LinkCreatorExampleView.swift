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

struct LinkCreatorExampleView: View {
  @EnvironmentObject var model: LinkModel
  @State var dynamicLinkLongURL: URL?
  @State var dynamicLinkShortURL: URL?

  fileprivate func createAndShortenLink() {
    let generator = LinkCreatorExample(parameterStates: model.linkParameterValues)
    do {
      let dynamicLinkComponents = try generator.generateDynamicLinkComponents()
      if let longURL = dynamicLinkComponents.url {
        dynamicLinkLongURL = longURL
        Task {
          let (shortURL, warnings) = try await dynamicLinkComponents.shorten()
          dynamicLinkShortURL = shortURL
          print(warnings)
        }
      }
    } catch {
      print(error.localizedDescription)
    }
  }

  var body: some View {
    Form {
      LinkCreatorSectionView(dynamicLinkURL: $dynamicLinkLongURL, title: "Long Link")
      LinkCreatorSectionView(dynamicLinkURL: $dynamicLinkShortURL, title: "Short Link")
    }.onAppear(perform: createAndShortenLink)
  }
}

struct LinkCreatorSectionView: View {
  @Binding var dynamicLinkURL: URL?
  let title: String

  var body: some View {
    Section(content: {
      if let dynamicLinkLongURL = dynamicLinkURL {
        Link(destination: dynamicLinkLongURL) {
          Text(dynamicLinkLongURL.absoluteString)
        }
      } else {
        ProgressView {
          Text("Creating Link")
        }
      }
    }, header: {
      Label(title, systemImage: "link")
    })
  }
}

struct GeneratedDynamicLinkView_Previews: PreviewProvider {
  static var previews: some View {
    LinkCreatorExampleView().environmentObject(LinkModel())
  }
}
