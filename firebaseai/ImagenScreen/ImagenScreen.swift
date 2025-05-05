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

import SwiftUI
import GenerativeAIUIComponents
import FirebaseAI // Import FirebaseAI

struct ImagenScreen: View {
  // Use @StateObject and initialize via init
  @StateObject var viewModel: ImagenViewModel

  enum FocusedField: Hashable {
    case prompt // Rename for clarity
  }

  @FocusState var focusedField: FocusedField?

  // Initializer accepting FirebaseAI
  init(firebaseAI: FirebaseAI) {
     _viewModel = StateObject(wrappedValue: ImagenViewModel(firebaseAI: firebaseAI))
  }


  var body: some View {
    ZStack { // Use ZStack for progress overlay
      VStack {
        // Input field using viewModel.userInput
        InputField("Enter a prompt to generate an image", text: $viewModel.userInput) {
          Image(systemName: viewModel.inProgress ? "stop.circle.fill" : "sparkles") // Use sparkles icon
            .font(.title)
            .foregroundColor(viewModel.inProgress || viewModel.userInput.isEmpty ? .gray : .accentColor) // Dynamic color
        }
        .focused($focusedField, equals: .prompt)
        .onSubmit { sendOrStop() }
        .disabled(viewModel.inProgress) // Disable input field when busy


         // Display error message if present
         if let errorMessage = viewModel.errorMessage {
             Text(errorMessage)
                 .foregroundColor(.red)
                 .padding(.horizontal)
                 .multilineTextAlignment(.center)
         }


        // ScrollView for the image grid
        ScrollView {
          // Define grid layout dynamically
          let columns: [GridItem] = [
             GridItem(.flexible(), spacing: 10), // Use flexible columns
             GridItem(.flexible(), spacing: 10)
          ]
          let spacing: CGFloat = 10


          LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(viewModel.images, id: \.self) { image in
              Image(uiImage: image)
                .resizable()
                .aspectRatio(1.0, contentMode: .fill) // Make images square (or use model's ratio)
                .frame(minWidth: 0, maxWidth: .infinity) // Allow flexible width
                .clipped() // Clip content to bounds
                .cornerRadius(12)
                // Add tap gesture for detail view or action
                // .onTapGesture { /* Handle tap */ }
            }
          }
          .padding(.horizontal, spacing)
          .padding(.top, spacing) // Add top padding
        }
         // Show placeholder if no images and not loading
         if viewModel.images.isEmpty && !viewModel.inProgress {
            Text("Generated images will appear here.")
               .foregroundColor(.gray)
               .padding()
         }
      }
      .navigationTitle("Imagen") // Simpler title


      // Progress Overlay
      if viewModel.inProgress {
        ProgressOverlay() // Use the existing ProgressOverlay struct
      }
    }
    .onAppear {
      focusedField = .prompt // Focus prompt field on appear
    }
    // Add a toolbar button for explicit generation? Or rely on onSubmit.
    // .toolbar {
    //    ToolbarItem(placement: .navigationBarTrailing) {
    //       Button("Generate", action: sendMessage)
    //          .disabled(viewModel.inProgress || viewModel.userInput.isEmpty)
    //    }
    // }
  }


  // Action triggered by onSubmit or button press
  private func sendMessage() {
    Task {
       focusedField = nil // Dismiss keyboard
       await viewModel.generateImage() // Call viewModel's method
       // Optionally re-focus after generation if needed, but usually not desired
       // focusedField = .prompt
    }
  }


  // Action for the input field's button (Send/Stop)
  private func sendOrStop() {
     focusedField = nil // Dismiss keyboard
    if viewModel.inProgress {
      viewModel.stop()
    } else {
      sendMessage()
    }
  }
}


// ProgressOverlay remains the same
struct ProgressOverlay: View {
  var body: some View {
    ZStack {
      // Use system background material for better adaptability
      Rectangle()
          .fill(.ultraThinMaterial)
          .ignoresSafeArea() // Cover the whole screen


      VStack(spacing: 12) {
        ProgressView()
          .scaleEffect(1.5)
        Text("Generating...") // Updated text
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
       .padding(30)
       .background(.regularMaterial) // Background for the content itself
       .cornerRadius(16)
       .shadow(radius: 8)
    }
  }
}


// Update Preview Provider
#Preview { // Use #Preview macro
   // Create a dummy FirebaseAI instance for preview
   let dummyAI = FirebaseAI.firebaseAI(backend: .googleAI())


   NavigationView { // Embed in NavigationView for title
      ImagenScreen(firebaseAI: dummyAI)
         .onAppear {
             // Example: Set preview state if needed
             // let vm = ImagenViewModel(firebaseAI: dummyAI)
             // vm.userInput = "a cat wearing a hat"
             // vm.images = [UIImage(systemName: "photo")!] // Placeholder image
             // Direct access complex with StateObject init.
         }
   }
}
