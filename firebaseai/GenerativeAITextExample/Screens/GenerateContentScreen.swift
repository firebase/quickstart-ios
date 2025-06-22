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
import SwiftUI
import FirebaseAI

struct GenerateContentScreen: View {
  let firebaseService: FirebaseAI
  @StateObject var viewModel: GenerateContentViewModel
  @State var userInput = ""

  init(firebaseService: FirebaseAI) {
    self.firebaseService = firebaseService
    _viewModel =
      StateObject(wrappedValue: GenerateContentViewModel(firebaseService: firebaseService))
  }

  enum FocusedField: Hashable {
    case message
  }

  @FocusState
  var focusedField: FocusedField?

  var body: some View {
    VStack {
      VStack(alignment: .leading) {
        Text("Enter some text, then tap on _Go_ to run generateContent on it.")
          .padding(.horizontal, 6)
        HStack(alignment: .top) {
          TextField("Enter generate content input", text: $userInput, axis: .vertical)
            .focused($focusedField, equals: .message)
            .textFieldStyle(.roundedBorder)
            .onSubmit {
              onGenerateContentTapped()
            }
          Button("Go") {
            onGenerateContentTapped()
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
    .navigationTitle("Text example")
  }

  private func onGenerateContentTapped() {
    focusedField = nil

    Task {
      await viewModel.generateContent(inputText: userInput)
    }
  }
}

#Preview {
  NavigationStack {
    GenerateContentScreen(firebaseService: FirebaseAI.firebaseAI())
  }
}
