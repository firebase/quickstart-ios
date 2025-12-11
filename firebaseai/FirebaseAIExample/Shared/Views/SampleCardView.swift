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

struct SampleCardView: View {
    let sample: Sample

    var body: some View {
        GroupBox {
            Text(sample.description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } label: {
            if let useCase = sample.useCases.first {
                Label(sample.title, systemImage: systemName(for: useCase))
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(color(for: useCase))
            } else {
                Text(sample.title)
                    .font(.system(size: 17, weight: .medium))
            }
        }
        .groupBoxStyle(CardGroupBoxStyle())
        .frame(maxWidth: .infinity, minHeight: 150, maxHeight: .infinity, alignment: .top)
    }

    private func systemName(for useCase: UseCase) -> String {
        switch useCase {
        case .all: "square.grid.2x2.fill"
        case .text: "text.bubble.fill"
        case .image: "photo.fill"
        case .video: "video.fill"
        case .audio: "waveform"
        case .document: "doc.fill"
        case .functionCalling: "gearshape.2.fill"
        }
    }

    private func color(for useCase: UseCase) -> Color {
        switch useCase {
        case .all:.primary
        case .text:.blue
        case .image:.purple
        case .video:.red
        case .audio:.orange
        case .document:.gray
        case .functionCalling:.green
        }
    }
}

public struct CardGroupBoxStyle: GroupBoxStyle {
    private var cornerRadius: CGFloat {
        if #available(iOS 26.0, *) {
            return 28
        } else {
            return 12
        }
    }

    public func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            configuration.label
            configuration.content
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

#Preview {
    let samples = [
        Sample(
            title: "Sample 1",
            description: "This is the first sample card.",
            useCases: [.text],
            navRoute: "ConversationScreen"
        ),
        Sample(
            title: "Sample 2",
            description: "This is the second sample card.",
            useCases: [.image],
            navRoute: "PhotoReasoningScreen"
        ),
        Sample(
            title: "Sample 3",
            description: "This is the third sample card.",
            useCases: [.video],
            navRoute: "ConversationScreen"
        ),
        Sample(
            title: "Sample 4",
            description: "This is the fourth sample card, which is a bit longer to see how the text wraps and if everything still aligns correctly.",
            useCases: [.audio],
            navRoute: "ConversationScreen"
        ),
    ]

    ScrollView {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: 16) {
            ForEach(samples) { sample in
                SampleCardView(sample: sample)
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
