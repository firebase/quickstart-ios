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

struct LinkConfigurationView: View {
  @EnvironmentObject var model: LinkModel
  @State var showGeneratedLinkView: Bool = false

  var body: some View {
    Form {
      Section(header: Text("Required Components")) {
        ForEach(LinkModel.requiredLinkComponents) { component in
          NavigationLink {
            LinkComponentView(linkComponent: component)
          } label: {
            HStack {
              Text(component.name)
              if let componentState = model.linkComponentStates[component.id] {
                switch componentState {
                case .valid:
                  Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                case .missingRequiredParameters:
                  Image(systemName: "exclamationmark.octagon.fill").foregroundColor(.red)
                case .unspecified:
                  EmptyView()
                }
              }
            }
          }
        }
      }

      Section(header: Text("Optional Components")) {
        ForEach(LinkModel.optionalLinkComponents) { component in
          NavigationLink {
            LinkComponentView(linkComponent: component)
          } label: {
            HStack {
              Text(component.name)
              if let componentState = model.linkComponentStates[component.id] {
                switch componentState {
                case .valid:
                  Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                case .missingRequiredParameters:
                  Image(systemName: "exclamationmark.octagon.fill").foregroundColor(.red)
                case .unspecified:
                  EmptyView()
                }
              }
            }
          }
        }
      }

      Section {
        Button(action: {
          showGeneratedLinkView.toggle()
        }) {
          Label("Generate Dynamic Link", systemImage: "link.badge.plus")
        }.disabled(!model.missingParameterIDs.isEmpty)
      }
    }.sheet(isPresented: $showGeneratedLinkView) {
      LinkCreatorExampleView()
    }
    .navigationTitle("Dynamic Link Generator")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct LinkGeneratorView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      LinkConfigurationView().environmentObject(LinkModel())
    }
  }
}
