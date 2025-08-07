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

// Source: ConversationKit (https://github.com/peterfriese/ConversationKit)
// Copyright belongs to the original author. Used under the terms of the repository's license.

import SwiftUI
import MarkdownUI

extension EnvironmentValues {
  @Entry var onSendMessageAction: (_ message: String) async -> Void = { message in
    // no-op
  }
}

public extension View {
  func onSendMessage(_ action: @escaping (_ message: String) async -> Void) -> some View {
    environment(\.onSendMessageAction, action)
  }
}

extension EnvironmentValues {
  @Entry var modelError: Error? = nil
}

public extension View {
  func errorState(_ error: Error?) -> some View {
    environment(\.modelError, error)
  }
}

public struct ConversationView<Content>: View where Content: View {
  @Binding var messages: [ChatMessage]

  @State private var scrolledID: ChatMessage.ID?

  @State private var userPrompt: String

  @FocusState private var focusedField: FocusedField?
  enum FocusedField {
    case message
  }

  @Environment(\.onSendMessageAction) private var onSendMessageAction
  @Environment(\.modelError) private var modelError

  private let content: (ChatMessage) -> Content

  public init(messages: Binding<[ChatMessage]>, userPrompt: String = "",
              content: @escaping (ChatMessage) -> Content) {
    _messages = messages
    _userPrompt = State(initialValue: userPrompt)
    self.content = content
  }

  public var body: some View {
    ZStack(alignment: .bottom) {
      ScrollView {
        LazyVStack(spacing: 20) {
          ForEach(messages) { message in
            content(message)
              .padding(.horizontal)
          }
          if let error = modelError {
            ErrorView(error: error)
              .tag("errorView")
          }
          Spacer()
            .frame(height: 50)
        }
        .scrollTargetLayout()
      }
      .scrollTargetBehavior(.viewAligned)
      .scrollBounceBehavior(.always)
      .scrollDismissesKeyboard(.interactively)
      .scrollPosition(id: $scrolledID, anchor: .top)

      MessageComposerView(userPrompt: $userPrompt)
        .padding(.bottom, 10) // keep distance from keyboard
        .focused($focusedField, equals: .message)
        .onSubmitAction {
          submit()
        }
    }
    .onTapGesture {
      focusedField = nil
    }
    .onChange(of: messages) { oldValue, newValue in
      scrolledID = messages.last?.id
    }
  }

  @MainActor func submit() {
    let prompt = userPrompt
    userPrompt = ""
    focusedField = .message

    Task {
      await onSendMessageAction(prompt)
    }
  }
}
