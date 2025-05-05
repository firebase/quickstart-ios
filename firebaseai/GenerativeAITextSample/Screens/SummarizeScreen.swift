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
import FirebaseAI // Import FirebaseAI


struct SummarizeScreen: View {
  // Use @StateObject and initialize via init
  @StateObject var viewModel: SummarizeViewModel
  // Removed @State var userInput, now managed by viewModel


  enum FocusedField: Hashable {
    case message // Rename to inputText or similar if preferred
  }


  @FocusState var focusedField: FocusedField?


  // Initializer accepting FirebaseAI
  init(firebaseAI: FirebaseAI) {
    _viewModel = StateObject(wrappedValue: SummarizeViewModel(firebaseAI: firebaseAI))
  }


  var body: some View {
    VStack {
      VStack(alignment: .leading) {
        Text("Enter text, then tap **Go** to summarize.") // Use markdown for Go
          .padding(.horizontal) // Use standard padding


        HStack(alignment: .center) { // Align center vertically might look better
          // Bind TextField to viewModel.userInput
          TextField("Enter text to summarize", text: $viewModel.userInput, axis: .vertical)
            .focused($focusedField, equals: .message)
            .textFieldStyle(.roundedBorder)
             .lineLimit(5...) // Allow multiple lines
            .onSubmit {
              onSummarizeTapped()
            }
          Button("Go", action: onSummarizeTapped)
             .buttonStyle(.borderedProminent) // Make button more prominent
             .disabled(viewModel.inProgress || viewModel.userInput.isEmpty) // Disable when busy or no input
        }
      }
      .padding() // Add padding around the input area


       // Display error message if present
       if let errorMessage = viewModel.errorMessage {
           Text(errorMessage)
               .foregroundColor(.red)
               .padding(.horizontal)
       }


      // Use ScrollView for potentially long output
      ScrollViewReader { proxy in
          ScrollView {
              VStack(alignment: .leading) {
                  if viewModel.inProgress && viewModel.outputText.isEmpty {
                      HStack {
                          ProgressView()
                          Text("Generating summary...")
                              .foregroundColor(.gray)
                      }
                      .padding()
                  } else if !viewModel.outputText.isEmpty {
                      HStack(alignment: .top) {
                          Image(systemName: "sparkles") // Or "doc.text.fill"
                              .font(.title2)
                              .foregroundColor(.accentColor)
                              .padding(.top, 5) // Adjust alignment


                          Markdown(viewModel.outputText)
                              .markdownTheme(.gitHub) // Apply theme
                              .textSelection(.enabled) // Allow text selection
                      }
                      .padding()
                      .id("output") // ID for scrolling
                  } else if !viewModel.inProgress {
                      Text("Output will appear here.")
                          .foregroundColor(.gray)
                          .padding()
                  }
              }
              .frame(maxWidth: .infinity, alignment: .leading) // Ensure VStack takes width
          }
          .onChange(of: viewModel.outputText) { newValue in
              if !newValue.isEmpty {
                  // Scroll to bottom when new output arrives
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                      withAnimation {
                          proxy.scrollTo("output", anchor: .bottom)
                      }
                  }
              }
          }
      }
    }
    .navigationTitle("Text Summary") // More specific title
    .onAppear {
       // Optionally clear state or set focus
       // viewModel.userInput = ""
       // viewModel.outputText = ""
       focusedField = .message
    }
  }


  private func onSummarizeTapped() {
    focusedField = nil // Dismiss keyboard


    Task {
      // Call the ViewModel's method which uses its own userInput
      await viewModel.generateSummary()
    }
  }
}


// Update Preview Provider
#Preview { // Use #Preview macro
   // Create a dummy FirebaseAI instance for preview
   let dummyAI = FirebaseAI.firebaseAI(backend: .googleAI())


   NavigationStack {
      SummarizeScreen(firebaseAI: dummyAI)
         .onAppear {
            // Example: Set initial state for previewing different scenarios
            // let vm = SummarizeViewModel(firebaseAI: dummyAI)
            // vm.userInput = "This is some text to be summarized in the preview."
            // vm.outputText = "This is a preview summary."
            // vm.inProgress = false
            // Direct access is complex with StateObject init.
         }
   }
}
