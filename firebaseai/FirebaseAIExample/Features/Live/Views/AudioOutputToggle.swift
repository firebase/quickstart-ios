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

struct AudioOutputToggle: View {
  @Binding var isEnabled: Bool
  var onChange: () -> Void = {}

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      Toggle("Audio Output", isOn: $isEnabled).onChange(of: isEnabled) { _, _ in
        onChange()
      }

      Text("""
      Audio output works best on physical devices. Enable this to test playback in the \
      simulator. Headphones recommended.
      """)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}

#Preview {
  AudioOutputToggle(isEnabled: .constant(false))
}
