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
import AVFoundation
import UniformTypeIdentifiers

@MainActor
class MultimodalViewModel: ObservableObject {
  @Published var messages = [ChatMessage]()
  @Published var initialPrompt: String = ""
  @Published var title: String = ""
  @Published var error: Error?
  @Published var inProgress = false

  @Published var presentErrorDetails: Bool = false

  @Published var attachments = [MultimodalAttachment]()

  private var model: GenerativeModel
  private var chat: Chat
  private var chatTask: Task<Void, Never>?
  private var sample: Sample?
  private let logger = Logger(subsystem: "com.example.firebaseai", category: "MultimodalViewModel")

  init(firebaseService: FirebaseAI, sample: Sample? = nil) {
    self.sample = sample

    model = firebaseService.generativeModel(
      modelName: "gemini-2.0-flash-001",
      systemInstruction: sample?.systemInstruction
    )

    chat = model.startChat()
    initialPrompt = sample?.initialPrompt ?? ""
    title = sample?.title ?? ""

    if let urlMetas = sample?.attachedURLs {
      Task {
        for urlMeta in urlMetas {
          if let attachment = await MultimodalAttachment.fromURL(
            urlMeta.url,
            mimeType: urlMeta.mimeType
          ) {
            self.addAttachment(attachment)
          }
        }
      }
    }
  }

  func sendMessage(_ text: String, streaming: Bool = true) async {
    error = nil
    if streaming {
      await internalSendMessageStreaming(text)
    } else {
      await internalSendMessage(text)
    }
  }

  func startNewChat() {
    stop()
    error = nil
    chat = model.startChat()
    messages.removeAll()
    attachments.removeAll()
    initialPrompt = ""
  }

  func stop() {
    chatTask?.cancel()
    error = nil
  }

  private func internalSendMessageStreaming(_ text: String) async {
    chatTask?.cancel()

    chatTask = Task {
      inProgress = true
      defer {
        inProgress = false
      }

      let userMessage = ChatMessage(content: text, participant: .user, attachments: attachments)
      messages.append(userMessage)
      let systemMessage = ChatMessage.pending(participant: .other)
      messages.append(systemMessage)

      do {
        var parts: [any PartsRepresentable] = [text]

        for attachment in attachments {
          if let inlineDataPart = attachment.toInlineDataPart() {
            parts.append(inlineDataPart)
          }
        }

        attachments.removeAll()

        let responseStream = try chat.sendMessageStream(parts)
        for try await chunk in responseStream {
          messages[messages.count - 1].pending = false
          if let text = chunk.text {
            messages[messages.count - 1]
              .content = (messages[messages.count - 1].content ?? "") + text
          }
        }
      } catch {
        self.error = error
        logger.error("\(error.localizedDescription)")
        let errorMessage = ChatMessage(content: "An error occurred. Please try again.",
                                       participant: .other,
                                       error: error,
                                       pending: false)
        messages[messages.count - 1] = errorMessage
      }
    }
  }

  private func internalSendMessage(_ text: String) async {
    chatTask?.cancel()

    chatTask = Task {
      inProgress = true
      defer {
        inProgress = false
      }
      let userMessage = ChatMessage(content: text, participant: .user, attachments: attachments)
      messages.append(userMessage)

      let systemMessage = ChatMessage.pending(participant: .other)
      messages.append(systemMessage)

      do {
        var parts: [any PartsRepresentable] = [text]

        for attachment in attachments {
          if let inlineDataPart = attachment.toInlineDataPart() {
            parts.append(inlineDataPart)
          }
        }

        attachments.removeAll()

        let response = try await chat.sendMessage(parts)

        if let responseText = response.text {
          messages[messages.count - 1].content = responseText
          messages[messages.count - 1].pending = false
        }
      } catch {
        self.error = error
        logger.error("\(error.localizedDescription)")
        let errorMessage = ChatMessage(content: "An error occurred. Please try again.",
                                       participant: .other,
                                       error: error,
                                       pending: false)
        messages[messages.count - 1] = errorMessage
      }
    }
  }

  func addAttachment(_ attachment: MultimodalAttachment) {
    var newAttachment = attachment
    newAttachment.loadingState = .loaded
    attachments.append(newAttachment)
  }

  func removeAttachment(_ attachment: MultimodalAttachment) {
    attachments.removeAll { $0.id == attachment.id }
  }

  func handleError(_ error: Error) {
    self.error = error
    logger.error("\(error.localizedDescription)")
  }
}
