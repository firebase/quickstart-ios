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

struct ContentView: View {
  // Receive the binding from FirebaseAISampleApp
  @Binding var selectedBackend: AIBackend

  @StateObject
  var viewModel = ConversationViewModel()

  @StateObject
  var functionCallingViewModel = FunctionCallingViewModel()

  var body: some View {
    NavigationStack {
      List {
        // Section for Backend Selection Picker
        Section("Configuration") {
          Picker("Select Backend", selection: $selectedBackend) {
            ForEach(AIBackend.allCases) { backend in
              Text(backend.rawValue).tag(backend)
            }
          }
        }

        // Section for Sample Screens
        Section("Samples") {
          NavigationLink {
            // Pass selected backend value to the screen
            SummarizeScreen(backend: selectedBackend)
          } label: {
            Label("Text", systemImage: "doc.text")
          }
          NavigationLink {
            // Pass selected backend value to the screen
            PhotoReasoningScreen(backend: selectedBackend)
          } label: {
            Label("Multi-modal", systemImage: "doc.richtext")
          }
          NavigationLink {
            // Pass selected backend value to the screen
            ConversationScreen(backend: selectedBackend)
              .environmentObject(viewModel)
          } label: {
          Label("Chat", systemImage: "ellipsis.message.fill")
        }
        NavigationLink {
          // Pass selected backend value to the screen
          FunctionCallingScreen(backend: selectedBackend)
            .environmentObject(functionCallingViewModel)
        } label: {
          Label("Function Calling", systemImage: "function")
        }
        NavigationLink {
          // Pass selected backend value to the screen
          ImagenScreen(backend: selectedBackend)
        } label: {
          Label("Imagen", systemImage: "camera.circle")
        }
      } // End Section "Samples"
      } // End List
      .navigationTitle("Generative AI Samples")
    } // End NavigationStack
  } // End body
} // End ContentView

#Preview {
  // Provide a constant binding for the preview
  ContentView(selectedBackend: .constant(.googleAI))
}
