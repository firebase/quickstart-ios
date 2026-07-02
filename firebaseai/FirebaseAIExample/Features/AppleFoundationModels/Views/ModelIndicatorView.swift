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

import SwiftUI

struct ModelIndicatorView: View {
  let isUsingLocalModel: Bool

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: isUsingLocalModel ? "iphone" : "cloud.fill")
      Text(isUsingLocalModel ? "Local (Apple)" : "Cloud (Gemini)")
    }
    .font(.caption)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(isUsingLocalModel ? Color.green.opacity(0.2) : Color.purple.opacity(0.2))
    .foregroundColor(isUsingLocalModel ? .green : .purple)
    .cornerRadius(8)
  }
}
