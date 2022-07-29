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

struct LinkComponentView: View {
  @EnvironmentObject var model: LinkModel
  let linkComponent: LinkComponent

  var body: some View {
    Form {
      if !linkComponent.requiredParameters.isEmpty {
        Section(content: {
          ForEach(linkComponent.requiredParameters) { parameter in
            ParameterValueEditorView(
              linkParameter: parameter,
              isRequired: true,
              parameterValue: model.parameterValue(for: parameter.id)
            )
          }
        }, header: {
          Text("Required Parameters")
        })
      }
      if !linkComponent.optionalParameters.isEmpty {
        Section(content: {
          ForEach(linkComponent.optionalParameters) { parameter in
            ParameterValueEditorView(
              linkParameter: parameter,
              isRequired: false,
              parameterValue: model.parameterValue(for: parameter.id)
            )
          }
        }, header: {
          Text("Optional Parameters")
        })
      }
    }.navigationTitle(linkComponent.name)
      .navigationBarTitleDisplayMode(.inline)
  }
}

struct LinkComponentView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      LinkComponentView(linkComponent: LinkComponent.googleAnalytics)
        .environmentObject(LinkModel())
    }
  }
}
