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

struct ProgressOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Material.ultraThinMaterial)
                    .frame(width: 120, height: 100)
                    .shadow(radius: 8)

                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)

                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
