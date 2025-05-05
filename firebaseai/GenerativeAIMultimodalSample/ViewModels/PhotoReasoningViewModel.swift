// Copyright 2023 Google LLC
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
import PhotosUI
import SwiftUI

@MainActor
class PhotoReasoningViewModel: ObservableObject {
  // ... (Constants and Logger remain the same) ...
  private static let largestImageDimension = 768.0
  private var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "generative-ai")


  // ... (@Published properties remain the same) ...
  @Published var userInput: String = ""
  @Published var selectedItems = [PhotosPickerItem]()
  @Published var outputText: String? = nil
  @Published var errorMessage: String?
  @Published var inProgress = false


  private var model: GenerativeModel

  // Updated initializer
  init(firebaseAI: FirebaseAI) {
    // Use the injected FirebaseAI instance
    // TODO: Make model name configurable or dynamic if needed
    model = firebaseAI.generativeModel(modelName: "gemini-1.5-flash-latest") // Consistent model name
  }

  func reason() async {
     // Check if model is initialized (it should be from init)
     // guard let model = self.model else { // Model is non-optional now
     //   logger.error("Model not initialized.")
     //   errorMessage = "Model not initialized."
     //   return
     // }


    defer {
      inProgress = false
    }

    do {
      inProgress = true
      errorMessage = nil
      outputText = "" // Reset output text

      // Validate user input and selected items
       guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
         errorMessage = "Please enter a question."
         inProgress = false // Ensure progress stops
         return
       }
       guard !selectedItems.isEmpty else {
          errorMessage = "Please select at least one image."
          inProgress = false // Ensure progress stops
          return
       }


      let prompt = "Look at the image(s), and then answer the following question: \(userInput)"

      var images = [any PartsRepresentable]()
      for item in selectedItems {
        // Handle potential errors during image loading/processing
        do {
          if let data = try await item.loadTransferable(type: Data.self) {
              guard let uiImage = UIImage(data: data) else {
                logger.warning("Failed to decode data as UIImage for item \(item.itemIdentifier ?? "unknown"). Skipping.")
                continue // Skip this item
              }

              // Resize image if necessary
              let imageToAppend: UIImage
              if uiImage.size.fits(largestDimension: PhotoReasoningViewModel.largestImageDimension) {
                 imageToAppend = uiImage
              } else {
                 guard let resizedImage = uiImage.preparingThumbnail(of: uiImage.size.aspectFit(largestDimension: PhotoReasoningViewModel.largestImageDimension)) else {
                   logger.warning("Failed to resize image \(item.itemIdentifier ?? "unknown"). Skipping.")
                   continue // Skip this item
                 }
                 imageToAppend = resizedImage
                 logger.info("Resized image \(item.itemIdentifier ?? "unknown")")
              }
               images.append(imageToAppend) // Append the successfully processed UIImage
            } else {
               logger.warning("Could not load data for item \(item.itemIdentifier ?? "unknown"). Skipping.")
            }
        } catch {
            logger.error("Error loading transferable data for item \(item.itemIdentifier ?? "unknown"): \(error.localizedDescription). Skipping.")
            // Optionally set errorMessage here too, or just log and continue
        }
      }

       // Check if any images were successfully processed
       guard !images.isEmpty else {
          errorMessage = "Could not process any of the selected images."
          inProgress = false
          return
       }


      // Construct the request parts: prompt first, then images
      var requestParts: [any PartsRepresentable] = [prompt]
      requestParts.append(contentsOf: images)


      // Use structured concurrency for the API call
      let outputContentStream = try model.generateContentStream(requestParts)


      // stream response
      var streamedOutput = "" // Accumulate stream text
      for try await outputContent in outputContentStream {
         guard let text = outputContent.text else {
            // Handle cases where a chunk might not have text (e.g., finish reason)
            logger.info("Received non-text chunk in stream.")
            continue
         }
         streamedOutput += text
         outputText = streamedOutput // Update published property progressively
      }
       // Final check if output is empty after stream (might happen with errors or empty responses)
       if streamedOutput.isEmpty && errorMessage == nil {
          outputText = "Model did not return any text." // Provide feedback
          logger.warning("Model stream finished but produced no text output.")
       }


    } catch let decodingError as DecodingError {
       logger.error("Decoding error: \(decodingError)")
       errorMessage = "Error processing response from the model: \(decodingError.localizedDescription)"
    } catch let apiError as GenerateContentError {
        logger.error("API Error: \(apiError)")
        errorMessage = "An error occurred while communicating with the AI model: \(apiError.localizedDescription)"
    } catch {
      // Catch any other unexpected errors
      logger.error("An unexpected error occurred: \(error.localizedDescription)")
      errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
       // Ensure outputText doesn't remain empty if an error happened mid-stream
       if outputText?.isEmpty ?? true {
          outputText = nil // Clear potentially partial output on error
       }
    }
  }
}

// Private extension remains the same
private extension CGSize {
  func fits(largestDimension length: CGFloat) -> Bool {
    return width <= length && height <= length
  }

  func aspectFit(largestDimension length: CGFloat) -> CGSize {
    let aspectRatio = width / height
    if width > height {
      let width = min(self.width, length)
      return CGSize(width: width, height: round(width / aspectRatio))
    } else {
      let height = min(self.height, length)
      return CGSize(width: round(height * aspectRatio), height: height)
    }
  }
}
