// Copyright 2025 Google LLC
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

import FirebaseAI
import Foundation
import OSLog
import SwiftUI

@MainActor
class ImagenViewModel: ObservableObject {
  private var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "generative-ai")

  @Published
  var userInput: String = ""

  @Published
  var images = [UIImage]()

  @Published
  var errorMessage: String?

  @Published
  var inProgress = false

  private let model: ImagenModel

  private var generateImagesTask: Task<Void, Never>?

  private let firebaseAI: FirebaseAI

  // 1. Initialize the Gemini service - Removed direct initialization

  init(firebaseAI: FirebaseAI) {
    self.firebaseAI = firebaseAI
    // 2. Configure Imagen settings
    let modelName = "imagen-3.0-generate-002"
    let safetySettings = ImagenSafetySettings(
      safetyFilterLevel: .blockLowAndAbove
    )
    var generationConfig = ImagenGenerationConfig()
    generationConfig.numberOfImages = 4
    generationConfig.aspectRatio = .landscape4x3

    // 3. Initialize the Imagen model using the injected firebaseAI instance
    model = firebaseAI.imagenModel(
      modelName: modelName,
      generationConfig: generationConfig,
      safetySettings: safetySettings
    )
  }

  func generateImage(prompt: String) async {
    stop()

    generateImagesTask = Task {
      inProgress = true
      defer {
        inProgress = false
      }

      do {
        // 4. Call generateImages with the text prompt
        let response = try await model.generateImages(prompt: prompt)

        // 5. Print the reason images were filtered out, if any.
        if let filteredReason = response.filteredReason {
          print("Image(s) Blocked: \(filteredReason)")
        }

        if !Task.isCancelled {
          // 6. Convert the image data to UIImage for display in the UI
          images = response.images.compactMap { UIImage(data: $0.data) }
        }
      } catch {
        if !Task.isCancelled {
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
