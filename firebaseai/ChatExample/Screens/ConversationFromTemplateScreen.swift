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
import GenerativeAIUIComponents
import SwiftUI

struct ConversationFromTemplateScreen: View {
  let firebaseService: FirebaseAI
  let title: String
  @StateObject var viewModel: ConversationFromTemplateViewModel

  @State
  private var userPrompt = ""

  @State
  private var userName = ""

  @State
  private var preferredLanguage = ""

  init(firebaseService: FirebaseAI, title: String) {
    self.title = title
    self.firebaseService = firebaseService
    _viewModel =
      StateObject(wrappedValue: ConversationFromTemplateViewModel(firebaseService: firebaseService))
  }

  enum FocusedField: Hashable {
    case message
  }

  @FocusState
  var focusedField: FocusedField?

  var body: some View {
    VStack {
      VStack {
        HStack {
          Text("Name:")
          TextField("Your name", text: $userName)
        }
        HStack {
          Text("Language:")
          TextField("Your preferred response language", text: $preferredLanguage)
        }
      }.padding()

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
    .onTapGesture {
      focusedField = nil
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button(action: newChat) {
          Image(systemName: "square.and.pencil")
        }
      }
    }
    .navigationTitle(title)
    .onAppear {
      focusedField = .message
    }
  }

  private func sendMessage() {
    Task {
      let prompt = userPrompt
      userPrompt = ""
      await viewModel.sendMessage(prompt, name: userName, language: preferredLanguage)
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

struct ConversationFromTemplateScreen_Previews: PreviewProvider {
  struct ContainerView: View {
    @StateObject var viewModel = ConversationFromTemplateViewModel(firebaseService: FirebaseAI
      .firebaseAI()) // Example service init

    var body: some View {
      ConversationFromTemplateScreen(
        firebaseService: FirebaseAI.firebaseAI(),
        title: "Chat from Template sample"
      )
      .onAppear {
        viewModel.messages = ChatMessage.samples
      }
    }
  }

  static var previews: some View {
    NavigationStack {
      ConversationFromTemplateScreen(
        firebaseService: FirebaseAI.firebaseAI(),
        title: "Chat from Template sample"
      )
    }
  }
}
