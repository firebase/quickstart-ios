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
import GenerativeAIUIComponents // Ensure this is imported if InputField/MessageView are from here
import SwiftUI

struct FunctionCallingScreen: View {
  // Use @StateObject and initialize via init
  @StateObject var viewModel: FunctionCallingViewModel

  @State private var userPrompt = "What is 100 Euros in U.S. Dollars?"

  enum FocusedField: Hashable {
    case message
  }

  @FocusState var focusedField: FocusedField?

  // Initializer accepting FirebaseAI
  init(firebaseAI: FirebaseAI) {
    _viewModel = StateObject(wrappedValue: FunctionCallingViewModel(firebaseAI: firebaseAI))
  }

  var body: some View {
    VStack {
      ScrollViewReader { scrollViewProxy in
        List {
          // ... (List content remains the same) ...
           Text("Interact with a currency conversion API using function calling in Gemini.")
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
          // ... (onChange logic remains the same) ...
           if viewModel.hasError {
            // Wait for a short moment to make sure we can actually scroll to the bottom.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
              withAnimation {
                scrollViewProxy.scrollTo("errorView", anchor: .bottom)
              }
              focusedField = .message
            }
          } else {
            guard let lastMessage = viewModel.messages.last else { return }

            // Wait for a short moment to make sure we can actually scroll to the bottom.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
              withAnimation {
                scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
              }
              focusedField = .message
            }
          }
        })
        .onTapGesture {
          focusedField = nil
        }
      }
      // ... (InputField remains the same) ...
       InputField("Message...", text: $userPrompt) {
        Image(systemName: viewModel.busy ? "stop.circle.fill" : "arrow.up.circle.fill")
          .font(.title)
      }
      .focused($focusedField, equals: .message)
      .onSubmit { sendOrStop() }
    }
    // ... (toolbar and navigationTitle remain the same) ...
     .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button(action: newChat) {
          Image(systemName: "square.and.pencil")
        }
      }
    }
    .navigationTitle("Function Calling")
    .onAppear {
      focusedField = .message
    }
  }

  // ... (sendMessage, sendOrStop, newChat methods remain the same) ...
   private func sendMessage() {
    Task {
      let prompt = userPrompt
      userPrompt = ""
      await viewModel.sendMessage(prompt, streaming: true) // Keep streaming true or make configurable
    }
  }

  private func sendOrStop() {
     focusedField = nil // Dismiss keyboard when sending/stopping

    if viewModel.busy {
      viewModel.stop()
    } else {
      sendMessage()
    }
  }

  private func newChat() {
    viewModel.startNewChat()
    userPrompt = "What is 100 Euros in U.S. Dollars?" // Reset prompt maybe?
    focusedField = .message // Focus field after new chat
  }
}

// Update Preview Provider
struct FunctionCallingScreen_Previews: PreviewProvider {
  static var previews: some View {
    // Create a dummy FirebaseAI instance for preview
    let dummyAI = FirebaseAI.firebaseAI(backend: .googleAI())

    NavigationStack {
      FunctionCallingScreen(firebaseAI: dummyAI)
         // Add sample data for preview if needed, similar to ConversationScreen
        .onAppear {
           // Example: Access viewModel to set sample messages if needed for preview design
           // let vm = FunctionCallingViewModel(firebaseAI: dummyAI) // Need instance access
           // vm.messages = ChatMessage.samples // Assuming samples exist
           // This pattern is complex with StateObject init, consider preview-specific setup
        }
    }
  }
}
