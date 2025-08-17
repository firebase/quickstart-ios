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
  @State private var selectedUseCase: UseCase = .all

  var filteredSamples: [Sample] {
    if selectedUseCase == .all {
      return Sample.samples
    } else {
      return Sample.samples.filter { $0.useCases.contains(selectedUseCase) }
    }
  }

  let columns = [
    GridItem(.adaptive(minimum: 150)),
  ]

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          // Backend Configuration
          VStack(alignment: .leading) {
            Text("Backend Configuration")
              .font(.system(size: 20, weight: .bold))
              .padding(.horizontal)

            Picker("Backend", selection: $selectedBackend) {
              ForEach(BackendOption.allCases) { option in
                Text(option.rawValue)
                  .tag(option)
              }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
          }

          // Use Case Filter
          VStack(alignment: .leading) {
            Text("Filter by use case")
              .font(.system(size: 20, weight: .bold))
              .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 10) {
                ForEach(UseCase.allCases) { useCase in
                  FilterChipView(useCase: useCase, isSelected: selectedUseCase == useCase) {
                    selectedUseCase = useCase
                  }
                }
              }
              .padding(.horizontal)
            }
          }

          // Samples
          VStack(alignment: .leading) {
            Text("Samples")
              .font(.system(size: 20, weight: .bold))
              .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 20) {
              ForEach(filteredSamples) { sample in
                NavigationLink(destination: destinationView(for: sample)) {
                  SampleCardView(sample: sample)
                }
                .buttonStyle(PlainButtonStyle())
              }
            }
            .padding(.horizontal)
          }
        }
        .padding(.vertical)
      }
      .background(Color(.systemGroupedBackground))
      .navigationTitle("Firebase AI Logic")
      .onChange(of: selectedBackend) { _, newBackend in
        firebaseService = newBackend.backendValue
      }
    }
  }

  @ViewBuilder
  private func destinationView(for sample: Sample) -> some View {
    switch sample.navRoute {
    case "ChatScreen":
      ChatScreen(firebaseService: firebaseService, sample: sample)
    case "ImagenScreen":
      ImagenScreen(firebaseService: firebaseService, sample: sample)
    case "MultimodalScreen":
      MultimodalScreen(firebaseService: firebaseService, sample: sample)
    case "FunctionCallingScreen":
      FunctionCallingScreen(firebaseService: firebaseService, sample: sample)
    case "GroundingScreen":
      GroundingScreen(firebaseService: firebaseService, sample: sample)
    default:
      EmptyView()
    }
  }
}

#Preview {
  ContentView()
}
