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

struct ParameterValueEditorView: View {
  let linkParameter: LinkParameter
  let isRequired: Bool
  @State var value: String = ""
  @EnvironmentObject var model: LinkModel
  @ObservedObject var parameterValue: LinkParameterState

  var body: some View {
    HStack {
      Text(linkParameter.name).bold().multilineTextAlignment(.trailing)
        .foregroundColor((isRequired && value.isEmpty) ? .red : .primary)
      TextField(linkParameter.name, text: $value) { isEditing in
        if !isEditing {
          model.updateParameterValue(for: linkParameter.id, newValue: value)
        }
      }.keyboardType(.webSearch).disableTextInputAutocapitalization().disableAutocorrection(true)
    }.onAppear {
      if value != parameterValue.value {
        value = parameterValue.value
      }
    }
  }
}

extension View {
  @ViewBuilder
  func disableTextInputAutocapitalization() -> some View {
    if #available(iOS 15, *) {
      textInputAutocapitalization(.never)
    } else {
      autocapitalization(.none)
    }
  }
}

struct ParameterValueEditorView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      ParameterValueEditorView(
        linkParameter: LinkParameter.link,
        isRequired: true,
        parameterValue: linkParameterWithValue()
      ).previewLayout(.sizeThatFits).previewDisplayName("Valid Parameter Value").padding()

      ParameterValueEditorView(
        linkParameter: LinkParameter.link,
        isRequired: true,
        parameterValue: LinkParameterState(parameterID: LinkParameter.link.id)
      ).previewLayout(.sizeThatFits).previewDisplayName("Empty Required Parameter").padding()
    }
  }

  static func linkParameterWithValue() -> LinkParameterState {
    let linkParameterValue = LinkParameterState(parameterID: LinkParameter.link.id)
    linkParameterValue.value = "http://www.google.com"
    return linkParameterValue
  }
}
