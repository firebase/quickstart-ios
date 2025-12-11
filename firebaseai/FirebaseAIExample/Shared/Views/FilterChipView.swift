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

struct FilterChipView: View {
    let useCase: UseCase
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(useCase.rawValue)
                .padding(.horizontal)
        }
        .filterChipStyle(isSelected: isSelected)
    }
}

private struct FilterChipStyle: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        if isSelected {
            content.buttonStyle(.borderedProminent)
        } else {
            content.buttonStyle(.bordered)
        }
    }
}

extension View {
    func filterChipStyle(isSelected: Bool) -> some View {
        modifier(FilterChipStyle(isSelected: isSelected))
    }
}

#Preview {
    VStack(spacing: 16) {
        FilterChipView(useCase: .text, isSelected: true) {}
        FilterChipView(useCase: .text, isSelected: false) {}
    }
}
