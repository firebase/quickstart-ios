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

import FirebaseAI
import SwiftUI

/// Displays the user's prompt in a chat bubble, aligned to the right.
struct UserPromptView: View {
  let prompt: String

  var body: some View {
    HStack {
      Spacer() // Aligns the bubble to the right
      Text(prompt)
        .padding(12)
        .background(Color.userPromptBackground)
        .foregroundColor(Color.userPromptText)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    // Set a max width to prevent the bubble from taking the full screen width.
    .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: .trailing)
  }
}

/// The content (text and sources) that goes inside the model's response bubble.
struct ModelResponseContentView: View {
  let text: String
  let groundingMetadata: GroundingMetadata?

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(text)

      if let groundingChunks = groundingMetadata?.groundingChunks, !groundingChunks.isEmpty {
        Divider()
        VStack(alignment: .leading) {
          Text("Sources")
            .font(.footnote)
            .foregroundColor(.secondary)

          ForEach(0 ..< groundingChunks.count, id: \.self) { index in
            if let webChunk = groundingChunks[index].web {
              SourceLinkView(
                title: webChunk.title ?? "Untitled Source",
                uri: webChunk.uri
              )
            }
          }
        }
      }
    }
  }
}

/// The complete visual component for the model's turn. It handles compliance checks internally.
struct ModelResponseTurnView: View {
  let response: GenerateContentResponse

  var body: some View {
    // Use `if-let` to safely unwrap the first candidate. This is the correct SwiftUI pattern.
    if let candidate = response.candidates.first {
      // A response is non-compliant ONLY if groundingMetadata exists but searchEntryPoint is nil.
      let isNonCompliant = (candidate.groundingMetadata != nil && candidate.groundingMetadata?
        .searchEntryPoint == nil)

      if isNonCompliant {
        ComplianceErrorView()
      } else {
        // This branch handles both compliant grounded responses and non-grounded responses.
        HStack(alignment: .top, spacing: 8) {
          VStack(alignment: .leading, spacing: 8) {
            ModelResponseContentView(
              // Use the convenience accessor on the response object.
              text: response.text ?? "No text in response.",
              groundingMetadata: candidate.groundingMetadata
            )
            .padding(12)
            .background(Color.modelResponseBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            if let searchEntryPoint = candidate.groundingMetadata?.searchEntryPoint {
              WebView(htmlString: searchEntryPoint.renderedContent)
                .frame(height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 22))
            }
          }
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: .leading)
      }
    } else {
      // This `else` branch handles the case where the response has no candidates.
      ComplianceErrorView(
        message: "The response was blocked or contained no content."
      )
    }
  }
}

/// A view to show when a response cannot be displayed due to compliance or other errors.
struct ComplianceErrorView: View {
  var message = "Could not display the response because it was missing required attribution components."

  var body: some View {
    HStack {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundColor(.orange)
      Text(message)
    }
    .padding()
    .background(Color.modelResponseBackground)
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

/// A simplified view for a single, clickable source link.
struct SourceLinkView: View {
  let title: String
  let uri: String?

  var body: some View {
    if let uri, let url = URL(string: uri) {
      Link(destination: url) {
        HStack(spacing: 4) {
          Image(systemName: "link")
            .font(.caption)
            .foregroundColor(.secondary)
          Text(title)
            .font(.footnote)
            .underline()
            .lineLimit(1)
            .multilineTextAlignment(.leading)
        }
      }
      .buttonStyle(.plain)
    }
  }
}
