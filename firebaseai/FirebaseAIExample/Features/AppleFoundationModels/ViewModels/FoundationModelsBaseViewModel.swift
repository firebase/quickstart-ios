// Copyright 2026 Google LLC
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

#if canImport(FoundationModels) && compiler(>=6.4)
  import Foundation
  import SwiftUI
  import Combine
  import FoundationModels
  import FirebaseAILogic

  enum ModelPreference: String, CaseIterable, Identifiable {
    case auto = "Auto (Local First)"
    case cloud = "Cloud Only"

    var id: String { rawValue }
  }

  @available(iOS 27.0, *)
  @MainActor
  class FoundationModelsBaseViewModel: ObservableObject {
    @Published var inProgress = false
    @Published var error: Error?
    @Published var modelPreference: ModelPreference = .auto
    @Published var isUsingLocalModel: Bool = false

    internal var activeTask: Task<Void, Never>?
    let backendType: BackendOption

    init(backendType: BackendOption) {
      self.backendType = backendType
    }

    func stopActiveTask() {
      activeTask?.cancel()
      activeTask = nil
      inProgress = false
    }

    internal func getFirebaseAI() -> FirebaseAI {
      switch backendType {
      case .googleAI:
        return FirebaseAI.firebaseAI(backend: .googleAI())
      case .vertexAI:
        // Using "global" as location for Foundation Models fallback compatibility
        return FirebaseAI.firebaseAI(backend: .vertexAI(location: "global"))
      }
    }
  }
#endif
