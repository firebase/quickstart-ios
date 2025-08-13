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
import SwiftUI
import ConversationKit

struct ChatScreen: View {
  let firebaseService: FirebaseAI
  @StateObject var viewModel: ChatViewModel
  
  init(firebaseService: FirebaseAI, sample: Sample? = nil) {
    self.firebaseService = firebaseService
    _viewModel =
      StateObject(wrappedValue: ChatViewModel(firebaseService: firebaseService,
                                              sample: sample))
  }

  var body: some View {
    NavigationStack {
      ConversationView(messages: $viewModel.messages
//                       ,userPrompt: viewModel.initialPrompt
      ) { message in
        MessageView(message: message)
      }
      .disableAttachments()
      .onSendMessage { message in
        Task {
          await viewModel.sendMessage(message.content ?? "", streaming: true)
        }
      }
      .environment(\.presentErrorAction, PresentErrorAction(handler: { error in
        viewModel.presentErrorDetails = true
      }))
      .sheet(isPresented: $viewModel.presentErrorDetails) {
        if let error = viewModel.error {
          ErrorDetailsView(error: error)
        }
      }
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button(action: newChat) {
            Image(systemName: "square.and.pencil")
          }
        }
      }
      .navigationTitle(viewModel.title)
      .navigationBarTitleDisplayMode(.inline)
    }
  }

  private func newChat() {
    viewModel.startNewChat()
  }
}

#Preview {
  ChatScreen(firebaseService: FirebaseAI.firebaseAI())
}
