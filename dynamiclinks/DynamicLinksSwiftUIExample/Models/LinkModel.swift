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

enum DynamicLinkComponentState {
  case valid
  case missingRequiredParameters
  case unspecified
}

class LinkModel: ObservableObject {
  static let requiredLinkComponents: [LinkComponent] = LinkComponent.all
    .filter(\.isRequired)
  static let optionalLinkComponents: [LinkComponent] = LinkComponent.all
    .filter(\.isOptional)

  let linkParameterValues: [LinkParameter.ID: LinkParameterState] =
    .init(uniqueKeysWithValues: LinkParameter.all
      .map { ($0.id, LinkParameterState(parameterID: $0.id)) })

  @Published var missingParameterIDs: Set<LinkParameter.ID> = []
  @Published var linkComponentStates: [LinkComponent.ID: DynamicLinkComponentState] = [:]

  init() {
    validateComponents()
  }

  func validateComponents() {
    for linkComponent in LinkComponent.requiredLinkComponents {
      var componentState: DynamicLinkComponentState = .valid
      for linkParameter in linkComponent.requiredParameters {
        if linkParameterValues.value(parameter: linkParameter) == nil {
          missingParameterIDs.insert(linkParameter.id)
          componentState = .missingRequiredParameters
        } else {
          missingParameterIDs.remove(linkParameter.id)
        }
      }
      linkComponentStates[linkComponent.id] = componentState
    }

    for linkComponent in LinkComponent.optionalLinkComponents {
      var componentState: DynamicLinkComponentState = .unspecified
      if linkComponent.allParameters.contains(where: { linkParameter in
        linkParameterValues.value(parameter: linkParameter) != nil
      }) {
        componentState = .valid
        for linkParameter in linkComponent.requiredParameters {
          if linkParameterValues.value(parameter: linkParameter) == nil {
            missingParameterIDs.insert(linkParameter.id)
            componentState = .missingRequiredParameters
          } else {
            missingParameterIDs.remove(linkParameter.id)
          }
        }
      }
      linkComponentStates[linkComponent.id] = componentState
    }
  }

  func parameterValue(for identifier: LinkParameter.ID) -> LinkParameterState {
    guard let linkParameterValue = linkParameterValues[identifier] else {
      fatalError("Unrecognized link parameter identifier \"\(identifier)\".")
    }
    return linkParameterValue
  }

  func updateParameterValue(for identifier: LinkParameter.ID, newValue: String) {
    let parameterValue: LinkParameterState = parameterValue(for: identifier)
    if parameterValue.value != newValue {
      parameterValue.value = newValue
      validateComponents()
    }
  }
}

extension Dictionary where Key == LinkParameter.ID, Value == LinkParameterState {
  func value(id: LinkParameter.ID) -> String? {
    guard let linkParameterValue = self[id] else {
      fatalError("Unrecognized link parameter identifier \"\(id)\".")
    }
    return linkParameterValue.value.emptyToNil
  }

  func value(parameter: LinkParameter) -> String? {
    return value(id: parameter.id)
  }
}

private extension String {
  var emptyToNil: String? {
    isEmpty ? nil : self
  }
}
