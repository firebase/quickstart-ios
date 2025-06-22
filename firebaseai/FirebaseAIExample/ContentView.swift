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

enum BackendOption: String, CaseIterable, Identifiable {
  case googleAI = "Gemini Developer API"
  case vertexAI = "Vertex AI Gemini API"
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
        Section("Configuration") {
          Picker("Backend", selection: $selectedBackend) {
            ForEach(BackendOption.allCases) { option in
              Text(option.rawValue).tag(option)
            }
          }
        }

        Section("Samples") {
          NavigationLink {
            GenerateContentScreen(firebaseService: firebaseService)
          } label: {
            Label("Generate Content", systemImage: "doc.text")
          }
          NavigationLink {
            PhotoReasoningScreen(firebaseService: firebaseService)
          } label: {
            Label("Multi-modal", systemImage: "doc.richtext")
          }
          NavigationLink {
            ConversationScreen(firebaseService: firebaseService)
          } label: {
            Label("Chat", systemImage: "ellipsis.message.fill")
          }
          NavigationLink {
            FunctionCallingScreen(firebaseService: firebaseService)
          } label: {
            Label("Function Calling", systemImage: "function")
          }
          NavigationLink {
            ImagenScreen(firebaseService: firebaseService)
          } label: {
            Label("Imagen", systemImage: "camera.circle")
          }
        }
      }
      .navigationTitle("Generative AI Samples")
      .onChange(of: selectedBackend) { newBackend in
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
