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
import FirebaseAI // Ensure FirebaseAI is imported

struct ImagenScreen: View {
  let backend: FirebaseAIBackend // Added property
  @StateObject var viewModel: ImagenViewModel // Changed initialization

  // Added initializer
  init(backend: FirebaseAIBackend) {
      self.backend = backend
      _viewModel = StateObject(wrappedValue: ImagenViewModel(backend: backend))
  }

  enum FocusedField: Hashable {
    case message
  }

  @FocusState
  var focusedField: FocusedField?

  var body: some View {
    ZStack {
      VStack {
        InputField("Enter a prompt to generate an image", text: $viewModel.userInput) {
          Image(
            systemName: viewModel.inProgress ? "stop.circle.fill" : "paperplane.circle.fill"
          )
          .font(.title)
        }
        .focused($focusedField, equals: .message)
        .onSubmit { sendOrStop() }

        ScrollView {
          let spacing: CGFloat = 10
          LazyVGrid(columns: [
            GridItem(.fixed(UIScreen.main.bounds.width / 2 - spacing), spacing: spacing),
            GridItem(.fixed(UIScreen.main.bounds.width / 2 - spacing), spacing: spacing),
          ], spacing: spacing) {
            ForEach(viewModel.images, id: \.self) { image in
              Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: UIScreen.main.bounds.width / 2 - spacing,
                       height: UIScreen.main.bounds.width / 2 - spacing)
                .cornerRadius(12)
                .clipped()
            }
          }
          .padding(.horizontal, spacing)
        }
      }
      if viewModel.inProgress {
        ProgressOverlay()
      }
    }
    .navigationTitle("Imagen sample")
    .onAppear {
      focusedField = .message
    }
  }

  private func sendMessage() {
    Task {
      await viewModel.generateImage(prompt: viewModel.userInput)
      focusedField = .message
    }
  }

  private func sendOrStop() {
    if viewModel.inProgress {
      viewModel.stop()
    } else {
      sendMessage()
    }
  }
}

struct ProgressOverlay: View {
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 16)
        .fill(Material.ultraThinMaterial)
        .frame(width: 120, height: 100)
        .shadow(radius: 8)

      VStack(spacing: 12) {
        ProgressView()
          .scaleEffect(1.5)

        Text("Loading...")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
    }
  }
}

// Preview needs update or removal if it relies on the initializer
/*
 #Preview {
  // Preview needs a backend instance
  ImagenScreen(backend: FirebaseAI.firebaseAI(backend: .googleAI())) // Example backend
 }
 */
