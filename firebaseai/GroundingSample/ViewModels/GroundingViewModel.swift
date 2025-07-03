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

@MainActor
class GroundingViewModel: ObservableObject {
  private var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "generative-ai")

  @Published var userInput: String = "What's the weather in Chicago this weekend?"
  @Published var sentPrompt: String = ""

  @Published var response: GenerateContentResponse?
  @Published var errorMessage: String?
  @Published var inProgress = false

  private let model: GenerativeModel

  init(firebaseService: FirebaseAI) {
    model = firebaseService.generativeModel(
      modelName: "gemini-2.5-flash",
      tools: [.googleSearch()]
    )
  }

  func generateGroundedResponse() async {
    guard !userInput.isEmpty else { return }

    inProgress = true
    defer { inProgress = false }

    errorMessage = nil
    response = nil
    sentPrompt = userInput

    do {
      let result = try await model.generateContent(userInput)

      response = result
      userInput = "" // Clear input field on success
    } catch {
      logger.error("Error generating content: \(error)")
      errorMessage = error.localizedDescription
    }
  }
}
