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
import GenerativeAIUIComponents
import SwiftUI
// Assuming AIBackend is accessible (moved to Common/AIBackend.swift)

struct ConversationScreen: View {
  // Add backend property, though ViewModel is injected via environment
  let backend: AIBackend

  @EnvironmentObject
  var viewModel: ConversationViewModel // ViewModel is injected, already initialized with backend

  @State
  private var userPrompt = ""

  enum FocusedField: Hashable {
    case message
  }

  @FocusState
  var focusedField: FocusedField?

  var body: some View {
    VStack {
      ScrollViewReader { scrollViewProxy in
        List {
          ForEach(viewModel.messages) { message in
            MessageView(message: message)
          }
          if let error = viewModel.error {
            ErrorView(error: error)
              .tag("errorView")
          }
        }
        .listStyle(.plain)
        .onChange(of: viewModel.messages, perform: { newValue in
          if viewModel.hasError {
            // wait for a short moment to make sure we can actually scroll to the bottom
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
              withAnimation {
                scrollViewProxy.scrollTo("errorView", anchor: .bottom)
              }
              focusedField = .message
            }
          } else {
            guard let lastMessage = viewModel.messages.last else { return }

            // wait for a short moment to make sure we can actually scroll to the bottom
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
              withAnimation {
                scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
              }
              focusedField = .message
            }
          }
        })
      }
      InputField("Message...", text: $userPrompt) {
        Image(systemName: viewModel.busy ? "stop.circle.fill" : "arrow.up.circle.fill")
          .font(.title)
      }
      .focused($focusedField, equals: .message)
      .onSubmit { sendOrStop() }
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button(action: newChat) {
          Image(systemName: "square.and.pencil")
        }
      }
    }
    .navigationTitle("Chat sample")
    .onAppear {
      focusedField = .message
    }
  }

  private func sendMessage() {
    Task {
      let prompt = userPrompt
      userPrompt = ""
      await viewModel.sendMessage(prompt, streaming: true)
    }
  }

  private func sendOrStop() {
    focusedField = nil

    if viewModel.busy {
      viewModel.stop()
    } else {
      sendMessage()
    }
  }

  private func newChat() {
    viewModel.startNewChat()
  }
}

struct ConversationScreen_Previews: PreviewProvider {
  // The ContainerView is less useful now as we need to pass backend to ViewModel
  // struct ContainerView: View {
  //   // Initialize ViewModel with a default backend for the preview
  //   @StateObject var viewModel = ConversationViewModel(backend: .googleAI)
  //
  //   var body: some View {
  //     ConversationScreen(backend: .googleAI) // Pass backend here too
  //       .environmentObject(viewModel)
  //       .onAppear {
  //         viewModel.messages = ChatMessage.samples
  //       }
  //   }
  // }

  static var previews: some View {
    NavigationStack {
      // Initialize the screen with a backend
      // Initialize the ViewModel with a backend and inject it
      ConversationScreen(backend: .googleAI)
        .environmentObject(ConversationViewModel(backend: .googleAI))
    }
  }
}
        }
