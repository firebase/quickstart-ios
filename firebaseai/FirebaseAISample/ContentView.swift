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
import FirebaseAI // Import FirebaseAI

struct ContentView: View {
  // State variable for the selected backend
  @State private var selectedBackend: Backend = .googleAI

  // Computed property to initialize FirebaseAI based on selection
  private var firebaseAI: FirebaseAI {
    switch selectedBackend {
    case .googleAI:
      return FirebaseAI.firebaseAI(backend: .googleAI())
    case .vertexAI:
      // Make sure you have a GoogleCloud project listed in your Firebase project.
      // Go to Project Settings -> Integrations -> Google Cloud -> Manage
      // And add your Google Cloud project ID and number there.
      return FirebaseAI.firebaseAI(backend: .vertexAI())
    }
  }

  var body: some View {
    NavigationStack {
      List {
        // Picker for backend selection
        Section("Backend Selection") {
          Picker("Select Backend", selection: $selectedBackend) {
            ForEach(Backend.allCases) { backend in
              Text(backend.description).tag(backend)
            }
          }
          .pickerStyle(.segmented) // Use segmented style for better UI
        }

        // Navigation Links updated to pass firebaseAI instance
        Section("Samples") {
          NavigationLink {
            // Pass the firebaseAI instance
            SummarizeScreen(firebaseAI: firebaseAI)
          } label: {
            Label("Text", systemImage: "doc.text")
          }
          NavigationLink {
            // Pass the firebaseAI instance
            PhotoReasoningScreen(firebaseAI: firebaseAI)
          } label: {
            Label("Multi-modal", systemImage: "doc.richtext")
          }
          NavigationLink {
            // Pass the firebaseAI instance
            ConversationScreen(firebaseAI: firebaseAI)
          } label: {
            Label("Chat", systemImage: "ellipsis.message.fill")
          }
          NavigationLink {
            // Pass the firebaseAI instance
            FunctionCallingScreen(firebaseAI: firebaseAI)
          } label: {
            Label("Function Calling", systemImage: "function")
          }
          NavigationLink {
            // Pass the firebaseAI instance
            ImagenScreen(firebaseAI: firebaseAI)
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
