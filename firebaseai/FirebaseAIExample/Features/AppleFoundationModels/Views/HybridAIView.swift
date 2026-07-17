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
  struct HybridAIView: View {
    @ObservedObject var viewModel: HybridAIViewModel

    var body: some View {
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Input Text")
            .font(.headline)
          TextEditor(text: $viewModel.inputText)
            .frame(height: 120)
            .padding(4)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(8)
        }

        Button(action: {
          viewModel.runSummarization()
        }) {
          HStack {
            Spacer()
            Image(systemName: "sparkles")
            Text("Summarise")
            Spacer()
          }
          .padding()
          .foregroundColor(.white)
          .background(Color.blue)
          .cornerRadius(10)
        }
        .disabled(viewModel.inProgress)

        if let summary = viewModel.outputSummary {
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Text("Summary Points")
                .font(.headline)
              Spacer()

              ModelIndicatorView(isUsingLocalModel: viewModel.isUsingLocalModel)
            }

            VStack(alignment: .leading, spacing: 8) {
              ForEach(summary.summaryPoints, id: \.self) { point in
                HStack(alignment: .top, spacing: 6) {
                  Text("•")
                    .bold()
                  Text(point)
                    .font(.subheadline)
                }
              }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
          }
          .transition(.opacity.combined(with: .slide))
        }
      }
    }
  }
#endif
