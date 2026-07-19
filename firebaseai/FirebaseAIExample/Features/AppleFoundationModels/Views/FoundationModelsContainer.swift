// Copyright 2026 Google LLC
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

#if canImport(FoundationModels) && compiler(>=6.4)
  import SwiftUI

  @available(iOS 27.0, *)
  struct FoundationModelsContainer<Content: View, VM: FoundationModelsBaseViewModel>: View {
    @ObservedObject var viewModel: VM
    @State private var presentErrorDetails = false
    let title: String
    let content: (VM) -> Content

    var body: some View {
      ZStack {
        ScrollView {
          content(viewModel)
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }

        if viewModel.inProgress {
          ProgressOverlay()
        }
      }
      .background(Color(.systemGroupedBackground))
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .topBarTrailing) {
          if viewModel.inProgress {
            Button(action: {
              viewModel.stopActiveTask()
            }) {
              Image(systemName: "stop.circle")
                .font(.title3)
            }
          }

          Menu {
            Picker("Model Preference", selection: $viewModel.modelPreference) {
              ForEach(ModelPreference.allCases) { pref in
                Text(pref.rawValue).tag(pref)
              }
            }
          } label: {
            Image(systemName: "cpu")
          }
        }
      }
      .sheet(isPresented: $presentErrorDetails, onDismiss: { viewModel.error = nil }) {
        if let error = viewModel.error {
          ErrorDetailsView(error: error)
        }
      }
      .onChange(of: viewModel.error != nil) { oldValue, newValue in
        if newValue {
          presentErrorDetails = true
        }
      }
    }
  }
#endif
