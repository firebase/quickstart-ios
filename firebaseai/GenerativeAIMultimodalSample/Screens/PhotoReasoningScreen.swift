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

import GenerativeAIUIComponents
import MarkdownUI
import PhotosUI
import SwiftUI
import FirebaseAI // Import FirebaseAI

struct PhotoReasoningScreen: View {
  // Use @StateObject and initialize via init
  @StateObject var viewModel: PhotoReasoningViewModel

  enum FocusedField: Hashable {
    case message
  }

  @FocusState var focusedField: FocusedField?

  // Initializer accepting FirebaseAI
  init(firebaseAI: FirebaseAI) {
    _viewModel = StateObject(wrappedValue: PhotoReasoningViewModel(firebaseAI: firebaseAI))
  }


  var body: some View {
    VStack {
      // Use the specific MultimodalInputField if it's defined in GenerativeAIUIComponents
      MultimodalInputField(text: $viewModel.userInput, selection: $viewModel.selectedItems)
        .focused($focusedField, equals: .message)
        .onSubmit {
          onSendTapped()
        }
        // Display error message if present
         if let errorMessage = viewModel.errorMessage {
             Text(errorMessage)
                 .foregroundColor(.red)
                 .padding(.horizontal)
         }


      ScrollViewReader { scrollViewProxy in
        List {
          // Display output or progress/placeholder
          if viewModel.inProgress && (viewModel.outputText == nil || viewModel.outputText!.isEmpty) {
             HStack {
                 ProgressView()
                 Text("Generating response...")
                    .foregroundColor(.gray)
             }
             .listRowSeparator(.hidden)
          } else if let outputText = viewModel.outputText, !outputText.isEmpty {
             HStack(alignment: .top) {
               // Keep the cloud icon or use another indicator
               Image(systemName: "sparkles") // Use sparkles or another relevant icon
                 .font(.title2)
                 .foregroundColor(.accentColor) // Use accent color


               Markdown(outputText) // Ensure MarkdownUI handles the text correctly
                 .markdownTheme(.gitHub) // Example theme
             }
             .listRowSeparator(.hidden)
             .id("output") // Add ID for scrolling
          }
           // Optionally add a placeholder when not inProgress and no output
           else if !viewModel.inProgress {
              Text("Enter a question and select images to start.")
                 .foregroundColor(.gray)
                 .listRowSeparator(.hidden)
           }
        }
        .listStyle(.plain)
         // Scroll to output when it changes
         .onChange(of: viewModel.outputText) { newValue in
             if let newValue = newValue, !newValue.isEmpty {
                 // Delay slightly to allow layout update
                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                     withAnimation {
                         scrollViewProxy.scrollTo("output", anchor: .bottom)
                     }
                 }
             }
         }
      }
    }
    .navigationTitle("Multimodal sample")
    .onAppear {
      // Optionally clear previous state on appear
      // viewModel.outputText = nil
      // viewModel.errorMessage = nil
      focusedField = .message
    }
     // Add a button to trigger sending if needed, or rely on onSubmit
     // .toolbar {
     //     ToolbarItem(placement: .navigationBarTrailing) {
     //         Button("Send", action: onSendTapped)
     //             .disabled(viewModel.inProgress || viewModel.userInput.isEmpty || viewModel.selectedItems.isEmpty)
     //     }
     // }
  }

  // MARK: - Actions

  private func onSendTapped() {
    focusedField = nil // Dismiss keyboard

    Task {
      await viewModel.reason()
    }
  }
}

// Update Preview Provider
#Preview { // Use #Preview macro
  // Create a dummy FirebaseAI instance for preview
   let dummyAI = FirebaseAI.firebaseAI(backend: .googleAI()) // Use appropriate backend


  NavigationStack {
     PhotoReasoningScreen(firebaseAI: dummyAI)
       // Add sample data for preview if needed
       .onAppear {
          // Example: Set some initial state for preview
          // let vm = PhotoReasoningViewModel(firebaseAI: dummyAI)
          // vm.outputText = "This is a preview response."
          // This direct access is complex with StateObject init.
       }
  }
}
