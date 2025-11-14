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

// Template Details
//
//  Configuration
//
// input:
//  default:
//    language: english
//  schema:
//    name: string
//    language?: string
//
//  Prompt and system instructions
//
//    {{role "system"}}
//    The user's name is {{name}}. They prefer to communicate in {{language}}.
//    {{role "user"}}
//    Say hello.
//

@MainActor
class GenerateContentFromTemplateViewModel: ObservableObject {
  private var logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.google.firebase.quickstart.FirebaseAIExample",
    category: "generative-ai"
  )

  @Published
  var outputText = ""

  @Published
  var errorMessage: String?

  @Published
  var inProgress = false

  private var model: TemplateGenerativeModel?

  init(firebaseService: FirebaseAI) {
    model = firebaseService.templateGenerativeModel()
  }

  func generateContentFromTemplate(name: String) async {
    defer {
      inProgress = false
    }
    guard let model else {
      return
    }

    do {
      inProgress = true
      errorMessage = nil
      outputText = ""

      let response = try await model.generateContent(
        templateID: "apple-qs-greeting",
        inputs: [
          "name": name,
          "language": "Spanish",
        ]
      )
      if let text = response.text {
        outputText = text
      }
    } catch {
      logger.error("\(error.localizedDescription)")
      errorMessage = error.localizedDescription
    }
  }
}
