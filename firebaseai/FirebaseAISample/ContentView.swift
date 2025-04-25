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
import FirebaseVertexAI // Import necessary for FirebaseAIBackend type

// Add this enum definition before the ContentView struct
enum BackendOption: String, CaseIterable, Identifiable {
    case googleAI = "Google AI"
    case vertexAI = "Vertex AI" // Assuming Vertex AI is a valid option here too
    var id: String { self.rawValue }

    // Helper to get the actual backend type
    // NOTE: This part might need adjustment based on the actual SDK structure for FirebaseAI
    // It's possible the SDK might not have a direct equivalent for `FirebaseAIBackend`
    // or the initialization might differ. This is a placeholder based on the VertexAI example.
    var backendValue: Any { // Using Any as a placeholder, refine if possible
        switch self {
        case .googleAI:
             // Placeholder: Replace with actual Firebase AI SDK initialization if available
             // return FirebaseAI.googleAI()
             return "GoogleAI_Backend_Placeholder" // Replace with actual backend instance/config
        case .vertexAI:
             // Placeholder: Replace with actual Firebase AI SDK initialization for VertexAI if available
             // return FirebaseAI.vertexAI()
             return "VertexAI_Backend_Placeholder" // Replace with actual backend instance/config
        }
    }
}


struct ContentView: View {
  // Add this state variable
  @State private var selectedBackend: BackendOption = .googleAI

  // @StateObject initializations removed as per requirement

  var body: some View {
    NavigationStack {
      List {
        // Add this Section for the Picker
        Section("Configuration") {
          Picker("Backend", selection: $selectedBackend) {
            ForEach(BackendOption.allCases) { option in
              Text(option.rawValue).tag(option)
            }
          }
        }

        // Existing NavigationLinks...
        Section("Samples") {
           NavigationLink {
             // Pass backend to the screen initializer
             SummarizeScreen(backend: selectedBackend.backendValue)
           } label: {
             Label("Text", systemImage: "doc.text")
           }
           NavigationLink {
             // Pass backend to the screen initializer
             PhotoReasoningScreen(backend: selectedBackend.backendValue)
           } label: {
             Label("Multi-modal", systemImage: "doc.richtext")
           }
           NavigationLink {
             // Pass backend to the screen initializer
             ConversationScreen(backend: selectedBackend.backendValue)
             // Removed .environmentObject
           } label: {
             Label("Chat", systemImage: "ellipsis.message.fill")
           }
           NavigationLink {
             // Pass backend to the screen initializer
             FunctionCallingScreen(backend: selectedBackend.backendValue)
             // Removed .environmentObject
           } label: {
             Label("Function Calling", systemImage: "function")
           }
           NavigationLink {
             // Pass backend to the screen initializer
             ImagenScreen(backend: selectedBackend.backendValue)
           } label: {
             Label("Imagen", systemImage: "camera.circle")
           }
        }
      }
      .navigationTitle("Generative AI Samples")
      // Add an onChange modifier if ViewModels need to be re-initialized
      // when the backend changes. This depends on whether they are created
      // directly here or passed down.
      // .onChange(of: selectedBackend) { newBackend in
      //    // Re-initialize ViewModels if necessary
      // }
    }
  }
}

#Preview {
  ContentView()
}
