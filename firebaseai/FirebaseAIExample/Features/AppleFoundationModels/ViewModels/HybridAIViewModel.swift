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

#if canImport(FoundationModels)
import Foundation
import SwiftUI
import Combine
import FoundationModels
import FirebaseAILogic

@available(iOS 27.0, *)
@MainActor
final class HybridAIViewModel: FoundationModelsBaseViewModel {
  @Published var inputText: String =
    "It is the quintessential autumn harvest fruit, famously baked into warm cinnamon pastries, dipped in sticky caramel on Halloween, and traditionally rumored to keep medical professionals at bay if eaten once a day."
  @Published var outputSummary: TextSummary?

  func runSummarization() {
    stopActiveTask()
    inProgress = true
    error = nil
    outputSummary = nil

    activeTask = Task {
      defer { self.inProgress = false }

      let instructions = Instructions {
        "Your job is to summarize the provided text in exactly 2 bullet points."
      }

      let availability = SystemLanguageModel.default.availability

      // Try local model first if it reports available and not forced to cloud
      if modelPreference == .auto, availability == .available {
        isUsingLocalModel = true
        do {
          let session = LanguageModelSession(
            model: SystemLanguageModel.default,
            instructions: instructions
          )
          let response = try await session.respond(
            to: inputText,
            generating: TextSummary.self
          )
          if !Task.isCancelled {
            self.outputSummary = response.content
          }
          return
        } catch {
          // Fall back to cloud model if local model fails
          if error.isMLAssetUnavailable {
            print("Local ML assets unavailable. Falling back to cloud model...")
          } else {
            print(
              "Local model failed: \(error.localizedDescription). Falling back to cloud model..."
            )
          }
        }
      }

      // Fallback to cloud model
      isUsingLocalModel = false
      do {
        let ai = getFirebaseAI()
        let model = ai.geminiLanguageModel(name: "gemini-3.1-flash-lite")
        let session = LanguageModelSession(
          model: model,
          instructions: instructions
        )
        let response = try await session.respond(
          to: inputText,
          generating: TextSummary.self
        )
        if !Task.isCancelled {
          self.outputSummary = response.content
        }
      } catch {
        if !Task.isCancelled {
          self.error = error
        }
      }
    }
  }
}
#endif
