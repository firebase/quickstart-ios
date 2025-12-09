// Copyright 2025 Google LLC
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

#if canImport(FirebaseAILogic)
  import FirebaseAILogic
#else
  import FirebaseAI
#endif
import SwiftUI
import ConversationKit

struct LiveScreen: View {
  let backendType: BackendOption
  @StateObject var viewModel: LiveViewModel

  init(backendType: BackendOption, sample: Sample? = nil) {
    self.backendType = backendType
    _viewModel =
      StateObject(wrappedValue: LiveViewModel(backendType: backendType,
                                              sample: sample))
  }

  var body: some View {
    VStack(spacing: 20) {
      ModelAvatar(isConnected: viewModel.state == .connected)
      TranscriptView(typewriter: viewModel.transcriptTypewriter)

      Spacer()
      if let error = viewModel.error {
        ErrorDetailsView(error: error)
      }
      if let tip = viewModel.tip, !viewModel.hasTranscripts {
        TipView(text: tip)
      }
      ConnectButton(
        state: viewModel.state,
        onConnect: viewModel.connect,
        onDisconnect: viewModel.disconnect
      )

      #if !targetEnvironment(simulator)
        VStack(alignment: .leading, spacing: 5) {
          Toggle("Audio Output", isOn: $viewModel.isAudioOutputEnabled)
            .toggleStyle(.switch)

          Text("""
          Audio output works best on physical devices. Enable this to test playback in the \
          simulator. Headphones are recommended.
          """)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      #endif
    }
    .padding()
    .navigationTitle(viewModel.title)
    .navigationBarTitleDisplayMode(.inline)
    .background(viewModel.backgroundColor ?? .clear)
  }
}

#Preview {
  LiveScreen(backendType: .googleAI)
}
