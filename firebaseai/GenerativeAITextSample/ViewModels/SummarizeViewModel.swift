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

@MainActor
class SummarizeViewModel: ObservableObject {
  private var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "generative-ai")

  // Input text managed by the ViewModel
  @Published var userInput: String = ""

  // Output and state properties
  @Published var outputText: String = "" // Initialize as empty string
  @Published var errorMessage: String?
  @Published var inProgress = false

  private var model: GenerativeModel

  // Updated initializer accepting FirebaseAI
  init(firebaseAI: FirebaseAI) {
     // Use the injected FirebaseAI instance
     // TODO: Make model name configurable or dynamic if needed
     model = firebaseAI.generativeModel(modelName: "gemini-1.5-flash-latest") // Consistent model name
     logger.info("SummarizeViewModel initialized with \(model.modelName)") // Log initialization
  }


  // Renamed function to reflect action based on internal state (userInput)
  func generateSummary() async {
     // Validate input
     guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        errorMessage = "Please enter text to summarize."
        return // Don't proceed if input is empty
     }


     // Check if model is initialized (it should be, but good practice)
     // guard let model = self.model else { // model is non-optional now
     //    logger.error("Model not initialized.")
     //    errorMessage = "Model not initialized."
     //    return
     // }


     defer {
       inProgress = false
     }


     do {
       inProgress = true
       errorMessage = nil
       outputText = "" // Clear previous output


       let prompt = "Summarize the following text for me: \(userInput)"
       logger.debug("Generating summary for prompt: \(prompt)")


       // Use structured concurrency for the API call
       let outputContentStream = try model.generateContentStream(prompt)


       // stream response
       var streamedOutput = ""
       for try await outputContent in outputContentStream {
         guard let line = outputContent.text else {
            logger.info("Received non-text chunk in stream.")
            continue
         }
         streamedOutput += line
         outputText = streamedOutput // Update published property progressively
       }


        // Handle empty response after stream
        if streamedOutput.isEmpty && errorMessage == nil {
           outputText = "Model did not return a summary."
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
        // Clear potentially partial output on error
        if outputText.isEmpty {
           outputText = "" // Ensure it's cleared or set to an error message
        }
     }
   }
}
