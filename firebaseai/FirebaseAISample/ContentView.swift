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
import FirebaseAI

struct ContentView: View {
  @State var selectedBackend: FirebaseAIBackend = .googleAI

  var firebaseAI: FirebaseAI {
    FirebaseAI.firebaseAI(backend: selectedBackend)
  }

  // Removed: @StateObject var viewModel = ConversationViewModel()

  // Removed: @StateObject var functionCallingViewModel = FunctionCallingViewModel()

  var body: some View {
    NavigationStack {
      List {
        Section("Backend Selection") {
          Picker("Select Backend", selection: $selectedBackend) {
            Text("Gemini Developer API").tag(FirebaseAIBackend.googleAI)
            Text("Vertex AI Gemini API").tag(FirebaseAIBackend.vertexAI)
          }
        }
        NavigationLink {
          SummarizeScreen(firebaseAI: firebaseAI)
        } label: {
          Label("Text", systemImage: "doc.text")
        }
        NavigationLink {
          PhotoReasoningScreen(firebaseAI: firebaseAI)
        } label: {
          Label("Multi-modal", systemImage: "doc.richtext")
        }
        // Update Chat NavigationLink to inject the ViewModel with the selected backend
        NavigationLink {
          ConversationScreen()
            .environmentObject(ConversationViewModel(firebaseAI: firebaseAI)) // Create and inject here
        } label: {
          Label("Chat", systemImage: "ellipsis.message.fill")
        }
        // Update Function Calling NavigationLink to inject the ViewModel with the selected backend
        NavigationLink {
          FunctionCallingScreen()
            .environmentObject(FunctionCallingViewModel(firebaseAI: firebaseAI)) // Create and inject here
        } label: {
          Label("Function Calling", systemImage: "function")
        }
        // Update Imagen NavigationLink to pass the firebaseAI instance
        NavigationLink {
          ImagenScreen(firebaseAI: firebaseAI) // Pass firebaseAI here
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
