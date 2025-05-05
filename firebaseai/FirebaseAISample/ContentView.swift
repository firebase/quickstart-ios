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
import FirebaseAI // Add import for FirebaseAI

// Define the Backend enum
enum Backend: String, CaseIterable, Identifiable {
  case googleAI = "Google AI" // Using more user-friendly raw values
  case vertexAI = "Vertex AI"
  var id: String { rawValue }
}

struct ContentView: View {
  // Remove the old @StateObject initializations
  // @StateObject var viewModel = ConversationViewModel()
  // @StateObject var functionCallingViewModel = FunctionCallingViewModel()

  // Add the state variable for the selected backend
  @State private var selectedBackend: Backend = .googleAI

  // Add the computed property for FirebaseAI instance
  private var firebaseAIInstance: FirebaseAI {
    FirebaseAI.firebaseAI(backend: selectedBackend == .googleAI ? .googleAI() : .vertexAI())
  }

  var body: some View {
    NavigationStack {
      List {
        // Add the Picker for backend selection
        Picker("Select Backend", selection: $selectedBackend) {
          ForEach(Backend.allCases) { backend in
            Text(backend.rawValue).tag(backend)
          }
        }
        .pickerStyle(.menu)

        // Update NavigationLinks to inject ViewModels initialized with firebaseAIInstance
        NavigationLink {
          SummarizeScreen(viewModel: SummarizeViewModel(firebaseAI: firebaseAIInstance))
        } label: {
          Label("Text", systemImage: "doc.text")
        }
        NavigationLink {
          PhotoReasoningScreen(viewModel: PhotoReasoningViewModel(firebaseAI: firebaseAIInstance))
        } label: {
          Label("Multi-modal", systemImage: "doc.richtext")
        }
        NavigationLink {
          // Initialize VM directly here, assuming ConversationScreen takes it in init
          ConversationScreen(viewModel: ConversationViewModel(firebaseAI: firebaseAIInstance))
        } label: {
          Label("Chat", systemImage: "ellipsis.message.fill")
        }
        NavigationLink {
          // Initialize VM directly here, assuming FunctionCallingScreen takes it in init
          FunctionCallingScreen(viewModel: FunctionCallingViewModel(firebaseAI: firebaseAIInstance))
        } label: {
          Label("Function Calling", systemImage: "function")
        }
        NavigationLink {
          ImagenScreen(viewModel: ImagenViewModel(firebaseAI: firebaseAIInstance))
        } label: {
          Label("Imagen", systemImage: "camera.circle")
        }
      }
      .navigationTitle("Generative AI Samples")
    }
  }
}

#Preview {
  ContentView()
}
