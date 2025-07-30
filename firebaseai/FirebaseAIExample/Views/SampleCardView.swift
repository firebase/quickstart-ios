// Copyright 2024 Google LLC
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
import GenerativeAIUIComponents

struct SampleCardView: View {
  let sample: Sample

  var body: some View {
    VStack(alignment: .leading) {
      Text(sample.title)
        .font(.system(size: 17, weight: .medium))
      Text(sample.description)
        .font(.system(size: 14))
        .foregroundColor(.secondary)
        .padding(.top, 4)
    }
    .padding()
    .frame(maxWidth: .infinity, minHeight: 150, maxHeight: .infinity, alignment: .top)
    .background(Color.white)
    .cornerRadius(12)
    .shadow(radius: 3)
  }
}
