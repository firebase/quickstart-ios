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

#if canImport(FirebaseAILogic)
  import FirebaseAILogic
#else
  import FirebaseAI
#endif
import Foundation
import UIKit

// Template Details
//
//  Configuration
//
//    input:
//      default:
//        language: "English"
//      schema:
//        name?: string
//        language?: string
//        message: string
//
//  Prompt and system instructions
//
//      {{role "system"}}
//      {{#if name}}The user's name is {{name}}.{{/if}}
//      The user prefers to communicate in {{language}}.
//      {{history}}
//      {{role "user"}}
//      {{message}}
//

@MainActor
class ConversationFromTemplateViewModel: ObservableObject {
  /// This array holds both the user's and the system's chat messages
  @Published var messages = [ChatMessage]()

  /// Indicates we're waiting for the model to finish
  @Published var busy = false

  @Published var error: Error?
  var hasError: Bool {
    return error != nil
  }

  private var model: TemplateGenerativeModel
  private var chat: TemplateChatSession
  private var stopGenerating = false

  private var chatTask: Task<Void, Never>?

  init(firebaseService: FirebaseAI) {
    model = firebaseService.templateGenerativeModel()
    chat = model.startChat(templateID: "apple-qs-chat")
  }

  func sendMessage(_ text: String, name: String, language: String) async {
    error = nil
    let name = name.isEmpty ? nil : name
    let language = language.isEmpty ? nil : language
    await internalSendMessage(text, name: name, language: language)
  }

  func startNewChat() {
    stop()
    error = nil
    chat = model.startChat(templateID: "apple-qs-chat")
    messages.removeAll()
  }

  func stop() {
    chatTask?.cancel()
    error = nil
  }

  private func internalSendMessage(_ text: String, name: String?, language: String?) async {
    chatTask?.cancel()

    chatTask = Task {
      busy = true
      defer {
        busy = false
      }

      // first, add the user's message to the chat
      let userMessage = ChatMessage(message: text, participant: .user)
      messages.append(userMessage)

      // add a pending message while we're waiting for a response from the backend
      let systemMessage = ChatMessage.pending(participant: .system)
      messages.append(systemMessage)

      do {
        var inputs = ["message": text]
        if let name {
          inputs["name"] = name
        }
        if let language {
          inputs["language"] = language
        }
        let response = try await chat.sendMessage(text, inputs: inputs)

        if let responseText = response.text {
          // replace pending message with backend response
          messages[messages.count - 1].message = responseText
          messages[messages.count - 1].pending = false
        }
      } catch {
        self.error = error
        print(error.localizedDescription)
        messages.removeLast()
      }
    }
  }
}
