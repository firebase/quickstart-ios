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

#if canImport(FirebaseAILogic)
  import FirebaseAILogic
#else
  import FirebaseAI
#endif
import Foundation
import OSLog
import SwiftUI

// Template Details
//
//  Configuration
//
//    input:
//      schema:
//        prompt: 'string'
//
//  Prompt and system instructions
//
//    Create an image containing {{prompt}}
//

@MainActor
class ImagenFromTemplateViewModel: ObservableObject {
  private var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "generative-ai")

  @Published
  var userInput: String = ""

  @Published
  var images = [UIImage]()

  @Published
  var errorMessage: String?

  @Published
  var inProgress = false

  private let model: TemplateImagenModel

  private var generateImagesTask: Task<Void, Never>?

  init(firebaseService: FirebaseAI) {
    model = firebaseService.templateImagenModel()
  }

  func generateImageFromTemplate(prompt: String) async {
    stop()

    generateImagesTask = Task {
      inProgress = true
      defer {
        inProgress = false
      }

      do {
        let response = try await model.generateImages(
          templateID: "image-generation-basic",
          inputs: [
            "prompt": prompt,
          ]
        )

        if !Task.isCancelled {
          images = response.images.compactMap { UIImage(data: $0.data) }
        }
      } catch {
        if !Task.isCancelled {
          logger.error("Error generating images from template: \(error)")
        }
      }
    }
  }

  func stop() {
    generateImagesTask?.cancel()
    generateImagesTask = nil
  }
}
