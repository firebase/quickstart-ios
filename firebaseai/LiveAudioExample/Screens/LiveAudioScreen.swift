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

import MarkdownUI
import SwiftUI
import GenerativeAIUIComponents
import FirebaseAI
import AVFoundation
import Accelerate
import Charts

struct LiveAudioScreen: View {
  let firebaseService: FirebaseAI
  @StateObject var viewModel: LiveViewModel

  init(firebaseService: FirebaseAI, backend: BackendOption) {
    self.firebaseService = firebaseService
    _viewModel = StateObject(wrappedValue: LiveViewModel(firebaseService: firebaseService, backend: backend))
  }

  var body: some View {
    VStack(spacing: 20) {
      ModelPhoto(isConnected: viewModel.state == .connected)
      TranscriptView(vm: viewModel.transcriptViewModel)

      Spacer()
      if let error = viewModel.error {
        LiveErrorView(error: error)
      }
      ConnectButton(state: viewModel.state, onConnect: viewModel.connect, onDisconnect: viewModel.disconnect)
    }
    .padding()
    .navigationTitle("Live Audio")
    .background(viewModel.backgroundColor ?? .clear)
  }
}


#Preview {
  LiveAudioScreen(firebaseService: FirebaseAI.firebaseAI(), backend: .googleAI)
}
