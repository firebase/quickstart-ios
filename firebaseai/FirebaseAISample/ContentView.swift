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

// BackendOption enum definition
enum BackendOption: String, CaseIterable, Identifiable {
  case googleAI = "Google AI"
  case vertexAI = "Vertex AI"
  var id: String { rawValue }

  var backendValue: FirebaseAI {
    switch self {
    case .googleAI:
      return FirebaseAI.firebaseAI(backend: .googleAI())
    case .vertexAI:
      return FirebaseAI.firebaseAI(backend: .vertexAI())
    }
  }
}

struct ContentView: View {
  @State private var selectedBackend: BackendOption = .googleAI
  @State private var firebaseService: FirebaseAI = FirebaseAI.firebaseAI(backend: .googleAI())

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

        Section("Samples") {
          NavigationLink {
            // Pass the service instance
            SummarizeScreen(firebaseService: firebaseService)
          } label: {
            Label("Text", systemImage: "doc.text")
          }
          NavigationLink {
            // Pass the service instance
            PhotoReasoningScreen(firebaseService: firebaseService)
          } label: {
            Label("Multi-modal", systemImage: "doc.richtext")
          }
          NavigationLink {
            // Pass the service instance
            ConversationScreen(firebaseService: firebaseService)
          } label: {
            Label("Chat", systemImage: "ellipsis.message.fill")
          }
          NavigationLink {
            // Pass the service instance
            FunctionCallingScreen(firebaseService: firebaseService)
          } label: {
            Label("Function Calling", systemImage: "function")
          }
          NavigationLink {
            // Pass the service instance
            ImagenScreen(firebaseService: firebaseService)
          } label: {
            Label("Imagen", systemImage: "camera.circle")
          }
        }
      }
      .navigationTitle("Generative AI Samples")
      .onChange(of: selectedBackend) { newBackend in
        // Update service when selection changes
        firebaseService = newBackend.backendValue
        // Note: This might cause views that hold the old service instance to misbehave
        // unless they are also correctly updated or recreated.
      }
    }
  }
}

#Preview {
  ContentView()
}
