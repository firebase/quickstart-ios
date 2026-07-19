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

  @available(iOS 27.0, *)
  @MainActor
  final class VisionIDViewModel: FoundationModelsBaseViewModel {
    @Published var selectedImage: UIImage?
    @Published var identifiedObject: IdentifiedObject?

    func identifySelectedImage() {
      guard let image = selectedImage else { return }
      stopActiveTask()
      inProgress = true
      error = nil
      identifiedObject = nil
      isUsingLocalModel = false

      activeTask = Task {
        defer { self.inProgress = false }

        guard let cgImage = image.cgImage else { return }

        let instructions = Instructions {
          "You are a visual object identifier."
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
              generating: IdentifiedObject.self
            ) {
              "Identify the primary object in this image. Be as specific as possible, categorize it, and provide a short 2-sentence description."
              Attachment(cgImage).label("image")
            }
            if !Task.isCancelled {
              self.identifiedObject = response.content
            }
            return
          } catch {
            guard !Task.isCancelled else { return }
            if error.isMLAssetUnavailable {
              print(
                "Local ML assets unavailable for Vision ID. Falling back to cloud model..."
              )
            } else {
              print(
                "Local model failed for Vision ID: \(error.localizedDescription). Falling back to cloud model..."
              )
            }
          }
        }

        // Fallback to cloud model
        isUsingLocalModel = false
        do {
          let ai = getFirebaseAI()
          let model = ai.geminiLanguageModel(name: "gemini-3.5-flash")
          let session = LanguageModelSession(
            model: model,
            instructions: instructions
          )
          let response = try await session.respond(
            generating: IdentifiedObject.self
          ) {
            "Identify the primary object in this image. Be as specific as possible, categorize it, and provide a short 2-sentence description."
            Attachment(cgImage).label("image")
          }

          if !Task.isCancelled {
            self.identifiedObject = response.content
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
