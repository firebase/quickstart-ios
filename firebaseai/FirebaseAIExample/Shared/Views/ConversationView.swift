// Copyright 2026 Google LLC
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

import SwiftUI

struct ConversationView<Content: View>: View {
  @Binding var messages: [ChatMessage]
  @Binding var attachments: [MultimodalAttachment]
  var userPrompt: String?
  var content: (ChatMessage) -> Content

  @State private var inputText: String = ""
  @FocusState private var isFocused: Bool

  private var hasAttachments: Bool = true
  private var attachmentActionsClosure: (() -> AnyView)? = nil
  private var onSendMessageClosure: ((ChatMessage) async -> Void)? = nil
  private var onErrorClosure: ((Error) -> Void)? = nil

  init(messages: Binding<[ChatMessage]>,
       attachments: Binding<[MultimodalAttachment]>,
       userPrompt: String? = "",
       @ViewBuilder content: @escaping (ChatMessage) -> Content) {
    self._messages = messages
    self._attachments = attachments
    self.userPrompt = userPrompt
    self.content = content
  }

  init(messages: Binding<[ChatMessage]>,
       userPrompt: String? = "",
       @ViewBuilder content: @escaping (ChatMessage) -> Content) {
    self._messages = messages
    self._attachments = .constant([])
    self.userPrompt = userPrompt
    self.content = content
    self.hasAttachments = false
  }

  var body: some View {
    VStack(spacing: 0) {
      ScrollViewReader { proxy in
        ScrollView {
          LazyVStack(spacing: 16) {
            ForEach(messages) { message in
              content(message)
                .id(message.id)
            }
          }
          .padding(.vertical)
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: messages) { _, newMessages in
          if let lastId = newMessages.last?.id {
            withAnimation {
              proxy.scrollTo(lastId, anchor: .bottom)
            }
          }
        }
        .onAppear {
          if let lastId = messages.last?.id {
            proxy.scrollTo(lastId, anchor: .bottom)
          }
          if let userPrompt = userPrompt, !userPrompt.isEmpty {
            inputText = userPrompt
          }
        }
      }

      Divider()

      // Composer area
      HStack(spacing: 12) {
        if hasAttachments, let actions = attachmentActionsClosure {
          Menu {
            actions()
          } label: {
            Image(systemName: "plus.circle.fill")
              .font(.system(size: 24))
              .foregroundColor(.blue)
          }
          .padding(.leading)
        }

        MessageComposerView(message: $inputText, attachments: $attachments)
          .disableAttachments(!hasAttachments)
          .onSubmitAction {
            submitMessage()
          }
          .focused($isFocused)
          .padding(.vertical, 8)
      }
      .background(Color(.systemBackground))
    }
    .environment(\.presentErrorAction) { error in
      if let onError = onErrorClosure {
        onError(error)
      }
    }
  }

  private func submitMessage() {
    let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedText.isEmpty || !attachments.isEmpty else { return }

    let messageToSend = ChatMessage(
      content: trimmedText,
      participant: .user,
      attachments: attachments
    )

    inputText = ""
    attachments = []
    isFocused = false

    Task {
      if let onSendMessage = onSendMessageClosure {
        await onSendMessage(messageToSend)
      }
    }
  }
}

extension ConversationView {
  func disableAttachments() -> Self {
    var copy = self
    copy.hasAttachments = false
    return copy
  }

  func attachmentActions<V: View>(@ViewBuilder _ actions: @escaping () -> V) -> Self {
    var copy = self
    copy.attachmentActionsClosure = { AnyView(actions()) }
    return copy
  }

  func onSendMessage(_ perform: @escaping (ChatMessage) async -> Void) -> Self {
    var copy = self
    copy.onSendMessageClosure = perform
    return copy
  }

  func onError(_ perform: @escaping (Error) -> Void) -> Self {
    var copy = self
    copy.onErrorClosure = perform
    return copy
  }
}

// Custom EnvironmentKey to support presenting errors from bubbles
struct PresentErrorActionKey: EnvironmentKey {
  static let defaultValue: ((Error) -> Void)? = nil
}

extension EnvironmentValues {
  var presentErrorAction: ((Error) -> Void)? {
    get { self[PresentErrorActionKey.self] }
    set { self[PresentErrorActionKey.self] = newValue }
  }
}
