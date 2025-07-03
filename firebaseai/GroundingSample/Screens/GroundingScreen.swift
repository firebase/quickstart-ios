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

import FirebaseAI
import SwiftUI

struct GroundingScreen: View {
  @StateObject var viewModel: GroundingViewModel

  init(firebaseService: FirebaseAI) {
    _viewModel = StateObject(wrappedValue: GroundingViewModel(firebaseService: firebaseService))
  }

  var body: some View {
    VStack(spacing: 0) {
      Divider()

      // Main content
      ScrollView {
        VStack(spacing: 20) {
          if viewModel.inProgress {
            ProgressView().padding()
          }

          VStack(spacing: 20) {
            if let response = viewModel.response {
              // User Prompt turn
              UserPromptView(prompt: viewModel.sentPrompt)
                .frame(maxWidth: .infinity, alignment: .trailing)

              // Model Response turn (handles compliance internally)
              ModelResponseTurnView(response: response)
                .frame(maxWidth: .infinity, alignment: .leading)

            } else if let errorMessage = viewModel.errorMessage {
              Text(errorMessage)
                .foregroundColor(.red)
                .padding()
            }
          }
          .padding()
        }
      }
      .background(Color.appBackground)
      .onTapGesture {
        hideKeyboard()
      }

      // Input Field
      GroundingInputView(
        userInput: $viewModel.userInput,
        isGenerating: viewModel.inProgress
      ) {
        Task {
          await viewModel.generateGroundedResponse()
        }
      }
    }
    .navigationTitle("Grounding")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                    to: nil, from: nil, for: nil)
  }
}

private struct GroundingInputView: View {
  @Binding var userInput: String
  var isGenerating: Bool
  var onSend: () -> Void

  var body: some View {
    HStack {
      TextField("Ask a question...", text: $userInput)
        .textFieldStyle(.plain)
        .padding(10)
        .background(Color.inputBackground)
        .cornerRadius(20)

      Button(action: onSend) {
        Image(systemName: "arrow.up.circle.fill")
          .font(.title)
          .foregroundColor(userInput.isEmpty ? .gray : .accentColor)
      }
      .disabled(userInput.isEmpty || isGenerating)
    }
    .padding()
    .background(Color.appBackground.shadow(radius: 2, y: -1))
  }
}

#Preview {
  NavigationView {
    GroundingScreen(firebaseService: FirebaseAI.firebaseAI())
  }
}
