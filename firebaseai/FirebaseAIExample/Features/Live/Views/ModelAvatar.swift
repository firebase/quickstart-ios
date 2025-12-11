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

struct ModelAvatar: View {
    var isConnected = false

    @State private var gradientAngle: Angle = .zero

    var colors: [Color] {
        if isConnected {
            [.red, .blue, .green, .yellow, .red]
        } else {
            [Color(red: 0.5, green: 0.5, blue: 0.5, opacity: 0.3)]
        }
    }

    var body: some View {
        Image("gemini-logo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .padding()
            .colorMultiply(.black)
            .maskedOverlay {
                AngularGradient(
                    gradient: Gradient(colors: colors),
                    center: .leading,
                    startAngle: gradientAngle,
                    endAngle: gradientAngle + .degrees(360)
                )
            }
            .onAppear {
                withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                    self.gradientAngle = .degrees(360)
                }
            }
    }
}

extension View {
    /// Creates an overlay which takes advantage of a mask to respect the size of the view.
    ///
    /// Especially useful when you want to create an overlay of an view with a non standard
    /// size.
    @ViewBuilder
    func maskedOverlay(mask: () -> some View) -> some View {
        overlay {
            mask()
                .mask { self }
        }
    }
}

#Preview {
    VStack {
        ModelAvatar(isConnected: true)
        ModelAvatar(isConnected: false)
    }
}
