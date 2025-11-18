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
#if canImport(FirebaseAILogic)
  import FirebaseAILogic
#else
  import FirebaseAI
#endif
import ConversationKit

struct ImagenFromTemplateScreen: View {
  let backendType: BackendOption
  @StateObject var viewModel: ImagenFromTemplateViewModel

  init(backendType: BackendOption, sample: Sample? = nil) {
    self.backendType = backendType
    _viewModel =
      StateObject(wrappedValue: ImagenFromTemplateViewModel(backendType: backendType,
                                                            sample: sample))
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
          MessageComposerView(message: $viewModel.userInput)
            .padding(.bottom, 10)
            .focused($focusedField, equals: .message)
            .disableAttachments()
            .onSubmitAction { sendOrStop() }

          if viewModel.error != nil {
            HStack {
              Text("An error occurred.")
              Button("More information", systemImage: "info.circle") {
                viewModel.presentErrorDetails = true
              }
              .labelStyle(.iconOnly)
            }
          }

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
      if viewModel.inProgress {
        ProgressOverlay()
      }
    }
    .onTapGesture {
      focusedField = nil
    }
    .sheet(isPresented: $viewModel.presentErrorDetails) {
      if let error = viewModel.error {
        ErrorDetailsView(error: error)
      }
    }
    .navigationTitle("Imagen Template")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      focusedField = .message
    }
  }

  private func sendMessage() {
    Task {
      await viewModel.generateImageFromTemplate(prompt: viewModel.userInput)
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

#Preview {
  ImagenFromTemplateScreen(backendType: .googleAI)
}
