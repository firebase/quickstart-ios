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

  // Input and Output properties
  @Published var userInput: String = ""
  @Published var images = [UIImage]() // Array to hold generated images
  @Published var errorMessage: String?
  @Published var inProgress = false

  // Imagen model instance
  private let model: ImagenModel

  // Task for managing image generation
  private var generateImagesTask: Task<Void, Never>?

  // Updated initializer accepting FirebaseAI instance
  init(firebaseAI: FirebaseAI) {
     // Configure Imagen settings (Keep these or make them configurable)
     // TODO: Consider making modelName, safetySettings, generationConfig configurable
     let modelName = "imagen-3.0-generate-002" // Or other available Imagen model
     let safetySettings = ImagenSafetySettings(
       safetyFilterLevel: .blockLowAndAbove // Adjust safety level as needed
     )
     var generationConfig = ImagenGenerationConfig()
     generationConfig.numberOfImages = 4 // Request multiple images
     generationConfig.aspectRatio = .landscape4x3 // Specify aspect ratio


     // Initialize the Imagen model using the injected FirebaseAI instance
     model = firebaseAI.imagenModel(
       modelName: modelName,
       generationConfig: generationConfig,
       safetySettings: safetySettings
     )
     logger.info("ImagenViewModel initialized with model: \(modelName)")
  }


  // Function to generate images based on the current userInput
  func generateImage() async {
     // Validate input
     guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        errorMessage = "Please enter a prompt to generate an image."
        return
     }


     stop() // Cancel any ongoing task


     generateImagesTask = Task {
       inProgress = true
       errorMessage = nil // Clear previous error
       // Optionally clear previous images: images = []
       defer {
         inProgress = false
       }


       do {
         logger.debug("Generating images for prompt: \(userInput)")
         // Call generateImages with the text prompt from userInput
         let response = try await model.generateImages(prompt: userInput)


         // Check for filtered reason
         if let filteredReason = response.filteredReason {
            logger.warning("Image(s) Blocked: \(filteredReason)")
            errorMessage = "Some images were blocked due to safety settings: \(filteredReason)"
            // Keep potentially unblocked images if any:
            if !Task.isCancelled {
               images = response.images.compactMap { UIImage(data: $0.data) }
            }
            // If all were blocked, images array will be empty.
            if images.isEmpty && errorMessage == nil { // Update error if all blocked
               errorMessage = "All generated images were blocked due to safety settings: \(filteredReason)"
            }


         } else if !Task.isCancelled {
           // Convert the image data to UIImage for display
           let generatedImages = response.images.compactMap { imageResponse -> UIImage? in
              if let data = imageResponse.data {
                 return UIImage(data: data)
              } else {
                 logger.warning("Received image response with no data.")
                 return nil
              }
           }


           if generatedImages.isEmpty && response.images.isEmpty {
              // Handle case where API returns success but no images (unlikely but possible)
              logger.warning("API returned success but no image data.")
              errorMessage = "The model did not return any images for this prompt."
           } else {
              images = generatedImages // Update the published array
              logger.info("Successfully generated \(images.count) images.")
           }
         }


       } catch let apiError as GenerateContentError { // Catch specific Imagen/GenerateContent errors
           logger.error("API Error generating images: \(apiError)")
           if !Task.isCancelled {
              errorMessage = "Error generating images: \(apiError.localizedDescription)"
           }
       } catch {
         // Catch other potential errors
         if !Task.isCancelled {
           logger.error("Unexpected error generating images: \(error)")
           errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
         }
       }
     }
  }


  // Function to cancel the ongoing generation task
  func stop() {
    if let task = generateImagesTask, !task.isCancelled {
       task.cancel()
       logger.info("Image generation task cancelled.")
       inProgress = false // Ensure progress stops immediately on manual stop
    }
    generateImagesTask = nil
  }
}
