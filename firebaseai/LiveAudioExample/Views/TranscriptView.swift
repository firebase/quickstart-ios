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

import SwiftUI

struct TranscriptView: View {
  @ObservedObject var vm: TranscriptViewModel

  var body: some View {
    VStack {
      ForEach(vm.audioTranscripts) { transcript in
        Text(transcript.message)
          .font(.title3)
          .frame(maxWidth: .infinity, alignment: .leading)
          .transition(.opacity)
          .padding(.horizontal)
      }
    }
  }
}

#Preview {
  let vm = TranscriptViewModel()
  TranscriptView(vm: vm).onAppear {
    vm
      .appendTranscript(
        "The sky is blue primarily because of a phenomenon called Rayleigh scattering, where tiny molecules of gas (mainly nitrogen and oxygen) in Earth's atmosphere scatter sunlight in all directions."
      )
  }
}
