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

import MarkdownUI
import MarkdownUI
import SwiftUI
import FirebaseAI // Ensure FirebaseAI is imported

struct SummarizeScreen: View {
  let backend: FirebaseAIBackend // Added property
  @StateObject var viewModel: SummarizeViewModel // Changed initialization
  @State var userInput = ""

  // Added initializer
  init(backend: FirebaseAIBackend) {
      self.backend = backend
      _viewModel = StateObject(wrappedValue: SummarizeViewModel(backend: backend))
  }

  enum FocusedField: Hashable {
    case message
  }

  @FocusState
  var focusedField: FocusedField?

  var body: some View {
    VStack {
      VStack(alignment: .leading) {
        Text("Enter some text, then tap on _Go_ to summarize it.")
          .padding(.horizontal, 6)
        HStack(alignment: .top) {
          TextField("Enter text summarize", text: $userInput, axis: .vertical)
            .focused($focusedField, equals: .message)
            .textFieldStyle(.roundedBorder)
            .onSubmit {
              onSummarizeTapped()
            }
          Button("Go") {
            onSummarizeTapped()
          }
          .padding(.top, 4)
        }
      }
      .padding(.horizontal, 16)

      List {
        HStack(alignment: .top) {
          if viewModel.inProgress {
            ProgressView()
          } else {
            Image(systemName: "cloud.circle.fill")
              .font(.title2)
          }

          Markdown("\(viewModel.outputText)")
        }
        .listRowSeparator(.hidden)
      }
      .listStyle(.plain)
    }
    .navigationTitle("Text sample")
  }

  private func onSummarizeTapped() {
    focusedField = nil

    Task {
      await viewModel.summarize(inputText: userInput)
    }
  }
}

// Preview needs update or removal if it relies on the initializer
/*
 #Preview {
  NavigationStack {
    // Preview needs a backend instance, e.g., .googleAI()
    SummarizeScreen(backend: FirebaseAI.firebaseAI(backend: .googleAI())) // Example backend
  }
 }
 */
