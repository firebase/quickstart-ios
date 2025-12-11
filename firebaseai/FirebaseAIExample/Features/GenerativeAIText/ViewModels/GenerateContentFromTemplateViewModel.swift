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
import Combine
import Foundation
import OSLog
import SwiftUI

@MainActor
class GenerateContentFromTemplateViewModel: ObservableObject {
    private var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "generative-ai")

    @Published
    var userInput: String = ""

    @Published
    var content: String = ""

    @Published
    var error: Error?
    var hasError: Bool {
        return error != nil
    }

    @Published
    var presentErrorDetails: Bool = false

    @Published
    var inProgress = false

    private let model: TemplateGenerativeModel
    private var backendType: BackendOption

    private var generateContentTask: Task<Void, Never>?

    private var sample: Sample?

    init(backendType: BackendOption, sample: Sample? = nil) {
        self.sample = sample
        self.backendType = backendType

        let firebaseService = backendType == .googleAI
            ? FirebaseAI.firebaseAI(backend: .googleAI())
            : FirebaseAI.firebaseAI(backend: .vertexAI())

        model = firebaseService.templateGenerativeModel()

        if let sample {
            userInput = sample.initialPrompt ?? ""
        }
    }

    func generateContent(prompt: String) async {
        stop()

        generateContentTask = Task {
            inProgress = true
            defer {
                inProgress = false
            }

            // Clear previous content before generating new content
            content = ""

            do {
                let responseStream = try model.generateContentStream(
                    templateID: "apple-qs-greeting",
                    inputs: [
                        "name": prompt,
                        "language": "Spanish",
                    ]
                )

                for try await chunk in responseStream {
                    if let text = chunk.text {
                        if !Task.isCancelled {
                            content += text
                        }
                    }
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error
                    logger.error("Error generating content from template: \(error)")
                }
            }
        }
    }

    func stop() {
        generateContentTask?.cancel()
        generateContentTask = nil
    }
}
