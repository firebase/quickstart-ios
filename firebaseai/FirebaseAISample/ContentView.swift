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

import SwiftUI

// Define the possible backend options
enum GeminiBackend: String, CaseIterable, Identifiable {
    case googleAI = "Gemini Developer API" // Use the display name for the raw value for easy Picker labeling
    case vertexAI = "Vertex AI Gemini API"

    var id: String { self.rawValue }
}

struct ContentView: View {
  @State private var selectedBackend: GeminiBackend = .googleAI

  // Initialize StateObjects in init
  @StateObject var viewModel: ConversationViewModel
  @StateObject var functionCallingViewModel: FunctionCallingViewModel

  // Initializer to set up StateObjects with the initial backend selection
  init() {
      _viewModel = StateObject(wrappedValue: ConversationViewModel(backend: .googleAI)) // Start with default
      _functionCallingViewModel = StateObject(wrappedValue: FunctionCallingViewModel(backend: .googleAI)) // Start with default
  }

  var body: some View {
      NavigationStack {
          Form {
              Section("Select Backend") {
                  Picker("Backend", selection: $selectedBackend) {
                      ForEach(GeminiBackend.allCases) { backend in
                          Text(backend.rawValue).tag(backend)
                      }
                  }
                  .pickerStyle(.segmented)
                  .onChange(of: selectedBackend) { oldBackend, newBackend in
                      // Reconfigure existing view models when selection changes
                      viewModel.reconfigure(backend: newBackend)
                      functionCallingViewModel.reconfigure(backend: newBackend)
                  }
              }

              // Cleaned list with backend passed to screen initializers
              List {
                  NavigationLink {
                      SummarizeScreen(backend: selectedBackend)
                  } label: {
                      Label("Text", systemImage: "doc.text")
                  }
                  NavigationLink {
                      PhotoReasoningScreen(backend: selectedBackend)
                  } label: {
                      Label("Multi-modal", systemImage: "doc.richtext")
                  }
                  NavigationLink {
                      // Pass backend, screen will use this potentially with the env object
                      ConversationScreen(backend: selectedBackend)
                          .environmentObject(viewModel)
                  } label: {
                      Label("Chat", systemImage: "ellipsis.message.fill")
                  }
                  NavigationLink {
                      // Pass backend, screen will use this potentially with the env object
                      FunctionCallingScreen(backend: selectedBackend)
                          .environmentObject(functionCallingViewModel)
                  } label: {
                      Label("Function Calling", systemImage: "function")
                  }
                  NavigationLink {
                      ImagenScreen(backend: selectedBackend)
                  } label: {
                      Label("Imagen", systemImage: "camera.circle")
                  }
              }
          }
      .navigationTitle("Generative AI Samples")
    }
  }
}

#Preview {
  ContentView()
}
