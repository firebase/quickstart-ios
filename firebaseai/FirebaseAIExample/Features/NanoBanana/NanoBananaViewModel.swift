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

#if canImport(FirebaseAILogic)
  import FirebaseAILogic
#else
  import FirebaseAI
#endif
import Foundation
import Combine
import OSLog
import SwiftUI

@MainActor
class NanoBananaViewModel: ObservableObject {
  private var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "generative-ai")

  @Published
  var initialPrompt: String = ""

  @Published
  var images = [UIImage]()

  @Published
  var error: Error?
  var hasError: Bool {
    return error != nil
  }

  @Published
  var presentErrorDetails: Bool = false

  @Published
  var inProgress = false

  private let model: GenerativeModel
  private var backendType: BackendOption

  private var generateImagesTask: Task<Void, Never>?

  private var sample: Sample?

  init(backendType: BackendOption, sample: Sample? = nil) {
    self.sample = sample
    self.backendType = backendType

    let firebaseService = backendType == .googleAI
      ? FirebaseAI.firebaseAI(backend: .googleAI())
      : FirebaseAI.firebaseAI(backend: .vertexAI())

    let modelName = "gemini-2.5-flash-image"
    let safetySettings = [
      SafetySetting(
        harmCategory: .civicIntegrity,
        threshold: .blockLowAndAbove
      ),
      SafetySetting(
        harmCategory: .dangerousContent,
        threshold: .blockLowAndAbove
      ),
      SafetySetting(
        harmCategory: .harassment,
        threshold: .blockLowAndAbove
      ),
      SafetySetting(
        harmCategory: .hateSpeech,
        threshold: .blockLowAndAbove
      ),
      SafetySetting(
        harmCategory: .sexuallyExplicit,
        threshold: .blockLowAndAbove
      )
    ]

    model = firebaseService.generativeModel(
      modelName: modelName,
      generationConfig: GenerationConfig(responseModalities: [.image]),
      safetySettings: safetySettings
    )

    initialPrompt = sample?.initialPrompt ?? ""
  }

  func generateImage(prompt: String) async {
    stop()

    generateImagesTask = Task {
      inProgress = true
      defer {
        inProgress = false
      }

      do {
        // 1. Call generateContent with the text prompt
        let response = try await model.generateContent(prompt)

        // 2. Print the reason images were blocked, if any.
        if let blockReason = response.promptFeedback?.blockReason {
          print("Image(s) Blocked: \(blockReason)")
        }

        if !Task.isCancelled {
          // 3. Convert the image data to UIImage for display in the UI
          images = response.inlineDataParts.compactMap { UIImage(data: $0.data) }
        }
      } catch {
        if !Task.isCancelled {
          self.error = error
          logger.error("Error generating images: \(error)")
        }
      }
    }
  }

  func stop() {
    generateImagesTask?.cancel()
    generateImagesTask = nil
  }
}
