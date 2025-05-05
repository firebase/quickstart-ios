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
import UIKit // Keep UIKit import if needed for other parts, otherwise remove if unused

@MainActor
class FunctionCallingViewModel: ObservableObject {
  // ... (@Published properties remain the same) ...
  @Published var messages = [ChatMessage]()
  @Published var busy = false
  @Published var error: Error?
  var hasError: Bool {
    return error != nil
  }

  private var functionCalls = [FunctionCallPart]()
  private var model: GenerativeModel
  private var chat: Chat
  private var chatTask: Task<Void, Never>?

  // Updated initializer
  init(firebaseAI: FirebaseAI) {
    // Use the injected FirebaseAI instance
    // TODO: Make model name configurable or dynamic if needed
    // TODO: Make tool configuration dynamic if needed
    model = firebaseAI.generativeModel(
      modelName: "gemini-1.5-flash-latest", // Use a consistent or configurable model name
      tools: [.functionDeclarations([
        FunctionDeclaration(
          name: "get_exchange_rate",
          description: "Get the exchange rate for currencies between countries",
          parameters: [
            "currency_from": .enumeration(
              values: ["USD", "EUR", "JPY", "GBP", "AUD", "CAD"],
              description: "The currency to convert from in ISO 4217 format"
            ),
            "currency_to": .enumeration(
              values: ["USD", "EUR", "JPY", "GBP", "AUD", "CAD"],
              description: "The currency to convert to in ISO 4217 format"
            ),
          ]
        ),
      ])]
    )
    chat = model.startChat()
  }

  // ... (Rest of the methods: sendMessage, startNewChat, stop, internalSendMessageStreaming, etc. remain the same) ...
   func sendMessage(_ text: String, streaming: Bool = true) async {
      error = nil
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

        print(messages)
        do {
          repeat {
            if streaming {
              try await internalSendMessageStreaming(text)
            } else {
              try await internalSendMessage(text)
            }
          } while !functionCalls.isEmpty
        } catch {
          self.error = error
          print(error.localizedDescription)
          messages.removeLast()
        }
      }
    }

    func startNewChat() {
      stop()
      error = nil
      chat = model.startChat()
      messages.removeAll()
    }

    func stop() {
      chatTask?.cancel()
      error = nil
    }

   private func internalSendMessageStreaming(_ text: String) async throws {
      let functionResponses = try await processFunctionCalls()
      let responseStream: AsyncThrowingStream<GenerateContentResponse, Error>
      if functionResponses.isEmpty {
        // Pass the user message text only if there are no function responses to process first
        responseStream = try chat.sendMessageStream(text)
      } else {
        for functionResponse in functionResponses {
          messages.insert(functionResponse.chatMessage(), at: messages.count - 1)
        }
        // Send the function responses back to the model
        responseStream = try chat.sendMessageStream([functionResponses.modelContent()])
      }
      // Process the stream regardless of whether it's from the initial text or function responses
      for try await chunk in responseStream {
        processResponseContent(content: chunk)
      }
    }


    private func internalSendMessage(_ text: String) async throws {
      let functionResponses = try await processFunctionCalls()
      let response: GenerateContentResponse
      if functionResponses.isEmpty {
        // Pass the user message text only if there are no function responses to process first
        response = try await chat.sendMessage(text)
      } else {
        for functionResponse in functionResponses {
          messages.insert(functionResponse.chatMessage(), at: messages.count - 1)
        }
        // Send the function responses back to the model
        response = try await chat.sendMessage([functionResponses.modelContent()])
      }
      // Process the response regardless of whether it's from the initial text or function responses
      processResponseContent(content: response)
    }


    func processResponseContent(content: GenerateContentResponse) {
      guard let candidate = content.candidates.first else {
        // If no candidate, maybe just remove pending message? Or handle differently?
        print("Warning: No candidate found in response.")
        if messages.last?.pending == true {
           messages.removeLast()
        }
        return // Exit if no candidate
      }

      // Ensure pending message exists before trying to modify it
      if let lastIndex = messages.lastIndex(where: { $0.pending }) {
         messages[lastIndex].pending = false // Mark as not pending once we start processing
         var accumulatedText = messages[lastIndex].message // Keep existing text if any

          for part in candidate.content.parts {
            switch part {
            case let textPart as TextPart:
              accumulatedText += textPart.text // Append new text
            case let functionCallPart as FunctionCallPart:
              // Insert the function call message *before* the placeholder message
              messages.insert(functionCallPart.chatMessage(), at: lastIndex)
              functionCalls.append(functionCallPart)
              // Potentially clear the placeholder text if a function call is the primary response part
              accumulatedText = ""
            default:
               print("Warning: Unsupported response part: \(part)")
            }
          }
         // Update the message content after processing all parts
         messages[lastIndex].message = accumulatedText
         // If the message is now empty after processing (e.g. only function call), remove it
         if messages[lastIndex].message.isEmpty && !messages[lastIndex].hasFunctionCall { // Add hasFunctionCall check if needed
            messages.remove(at: lastIndex)
         }

      } else {
         print("Warning: Tried to process response content but no pending message found.")
         // Handle cases where response comes unexpectedy? Maybe append as new system message?
         if let text = candidate.text {
             messages.append(ChatMessage(message: text, participant: .system))
         }
      }
    }


    func processFunctionCalls() async throws -> [FunctionResponsePart] {
      var functionResponses = [FunctionResponsePart]()
      // Use a temporary list to avoid concurrent modification issues if processFunctionCalls is re-entrant
      let callsToProcess = functionCalls
      functionCalls = [] // Clear original list

      for functionCall in callsToProcess {
        switch functionCall.name {
        case "get_exchange_rate":
          let exchangeRates = getExchangeRate(args: functionCall.args)
          functionResponses.append(FunctionResponsePart(
            name: "get_exchange_rate",
            response: exchangeRates
          ))
        default:
          // Handle unknown function call more gracefully, maybe return an error response part
          print("Error: Unknown function named \"\(functionCall.name)\".")
          functionResponses.append(FunctionResponsePart(
             name: functionCall.name,
             response: ["error": .string("Unknown function named \(functionCall.name).")]
          ))
          // Alternatively, throw an error: throw NSError(domain: "FunctionCallingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown function named "\(functionCall.name)"."])
        }
      }
      return functionResponses
    }

    // MARK: - Callable Functions

    func getExchangeRate(args: JSONObject) -> JSONObject {
      // 1. Validate and extract the parameters provided by the model (from a `FunctionCall`)
      guard case let .string(from) = args["currency_from"] else {
         print("Error: Missing or invalid `currency_from` parameter.")
         return ["error": .string("Missing or invalid `currency_from` parameter.")]
      }
      guard case let .string(to) = args["currency_to"] else {
         print("Error: Missing or invalid `currency_to` parameter.")
         return ["error": .string("Missing or invalid `currency_to` parameter.")]
      }

      // 2. Get the exchange rate (Keep existing logic)
      let allRates: [String: [String: Double]] = [
        "AUD": ["CAD": 0.89265, "EUR": 0.6072, "GBP": 0.51714, "JPY": 97.75, "USD": 0.66379],
        "CAD": ["AUD": 1.1203, "EUR": 0.68023, "GBP": 0.57933, "JPY": 109.51, "USD": 0.74362],
        "EUR": ["AUD": 1.6469, "CAD": 1.4701, "GBP": 0.85168, "JPY": 160.99, "USD": 1.0932],
        "GBP": ["AUD": 1.9337, "CAD": 1.7261, "EUR": 1.1741, "JPY": 189.03, "USD": 1.2836],
        "JPY": ["AUD": 0.01023, "CAD": 0.00913, "EUR": 0.00621, "GBP": 0.00529, "USD": 0.00679],
        "USD": ["AUD": 1.5065, "CAD": 1.3448, "EUR": 0.91475, "GBP": 0.77907, "JPY": 147.26],
      ]
      guard let fromRates = allRates[from] else {
        return ["error": .string("No data for currency \(from).")]
      }
      guard let toRate = fromRates[to] else {
        return ["error": .string("No data for currency \(to).")]
      }

      // 3. Return the exchange rates as a JSON object (returned to the model in a `FunctionResponse`)
      return ["rates": .number(toRate)]
    }
}

// Private extensions remain the same
private extension FunctionCallPart {
  func chatMessage() -> ChatMessage {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes] // Add withoutEscapingSlashes if needed

    let jsonData: Data
    do {
      jsonData = try encoder.encode(self)
    } catch {
       // Return an error message instead of fatalError
       return ChatMessage(message: "Error encoding function call: \(error.localizedDescription)", participant: .system, isError: true)
    }
    guard let json = String(data: jsonData, encoding: .utf8) else {
      // Return an error message instead of fatalError
      return ChatMessage(message: "Error converting function call JSON to String.", participant: .system, isError: true)
    }
    let messageText = "Function call requested by model:\n```json\n\(json)\n```" // Use json hint for markdown

    return ChatMessage(message: messageText, participant: .system)
  }
}

private extension FunctionResponsePart {
  func chatMessage() -> ChatMessage {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes] // Add withoutEscapingSlashes if needed

    let jsonData: Data
    do {
      jsonData = try encoder.encode(self)
    } catch {
      // Return an error message instead of fatalError
      return ChatMessage(message: "Error encoding function response: \(error.localizedDescription)", participant: .user, isError: true) // Mark as user participant as it's the app's response
    }
    guard let json = String(data: jsonData, encoding: .utf8) else {
      // Return an error message instead of fatalError
      return ChatMessage(message: "Error converting function response JSON to String.", participant: .user, isError: true)
    }
    let messageText = "Function response returned by app:\n```json\n\(json)\n```" // Use json hint for markdown

    return ChatMessage(message: messageText, participant: .user) // Function response is from the 'user' role perspective for the model
  }
}


private extension [FunctionResponsePart] {
  func modelContent() -> ModelContent {
    // Ensure parts conform to ModelContentRepresentable before creating ModelContent
    let modelParts = self.map { $0 as ModelContentRepresentable }
    return ModelContent(role: "function", parts: modelParts)
  }
}

// Add definition for ChatMessage.hasFunctionCall if needed (assuming it's defined elsewhere)
// extension ChatMessage {
//    var hasFunctionCall: Bool { /* logic to check if message contains function call info */ return false }
// }
