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
import FirebaseAI

struct ImagenScreen: View {
  let firebaseService: FirebaseAI
  @StateObject var viewModel: ImagenViewModel

  init(firebaseService: FirebaseAI) {
    self.firebaseService = firebaseService
    _viewModel = StateObject(wrappedValue: ImagenViewModel(firebaseService: firebaseService))
  }

  enum FocusedField: Hashable {
    case message
  }

  @FocusState
  var focusedField: FocusedField?

  var body: some View {
    ZStack {
      ScrollView {
        VStack {
          InputField("Enter a prompt to generate an image", text: $viewModel.userInput) {
            Image(
              systemName: viewModel.inProgress ? "stop.circle.fill" : "paperplane.circle.fill"
            )
            .font(.title)
          }
          .focused($focusedField, equals: .message)
          .onSubmit { sendOrStop() }

          let spacing: CGFloat = 10
          LazyVGrid(columns: [
            GridItem(.flexible(), spacing: spacing),
            GridItem(.flexible(), spacing: spacing),
          ], spacing: spacing) {
            ForEach(viewModel.images, id: \.self) { image in
              Image(uiImage: image)
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .cornerRadius(12)
                .clipped()
            }
          }
          .padding(.horizontal, spacing)
        }
      }
      .navigationTitle("Imagen example")
      .onAppear {
        focusedField = .message
      }
      
      if viewModel.inProgress {
        ProgressOverlay()
      }
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
      Color.black.opacity(0.3)
        .ignoresSafeArea()
      
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
}

#Preview {
  ImagenScreen(firebaseService: FirebaseAI.firebaseAI())
}
