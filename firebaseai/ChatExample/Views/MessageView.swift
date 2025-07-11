// Copyright 2023 Google LLC
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
import FirebaseAI

struct RoundedCorner: Shape {
  var radius: CGFloat = .infinity
  var corners: UIRectCorner = .allCorners

  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: radius, height: radius)
    )
    return Path(path.cgPath)
  }
}

extension View {
  func roundedCorner(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape(RoundedCorner(radius: radius, corners: corners))
  }
}

struct MessageContentView: View {
  var message: ChatMessage

  var body: some View {
    if message.pending {
      BouncingDots()
    } else {
      // Grounded Response
      if let groundingMetadata = message.groundingMetadata {
        GroundedResponseView(message: message, groundingMetadata: groundingMetadata)
      } else {
        // Non-grounded response
        ResponseTextView(message: message)
      }
    }
  }
}

struct ResponseTextView: View {
  var message: ChatMessage

  var body: some View {
    Markdown(message.message)
      .markdownTextStyle {
        FontFamilyVariant(.normal)
        FontSize(.em(0.85))
        ForegroundColor(message.participant == .system ? Color(UIColor.label) : .white)
      }
      .markdownBlockStyle(\.codeBlock) { configuration in
        configuration.label
          .relativeLineSpacing(.em(0.25))
          .markdownTextStyle {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.85))
            ForegroundColor(Color(.label))
          }
          .padding()
          .background(Color(.secondarySystemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .markdownMargin(top: .zero, bottom: .em(0.8))
      }
  }
}

struct GroundedResponseView: View {
  var message: ChatMessage
  var groundingMetadata: GroundingMetadata

  var body: some View {
    // We can only display a grounded response if the searchEntrypoint is non-nil.
    // If the searchEntrypoint is nil, we can only display the response if it's not grounded.
    let isNonCompliant = (!groundingMetadata.groundingChunks.isEmpty && groundingMetadata
      .searchEntryPoint == nil)
    if isNonCompliant {
      ComplianceErrorView()
    } else {
      HStack(alignment: .top, spacing: 8) {
        VStack(alignment: .leading, spacing: 8) {
          // Message text
          ResponseTextView(message: message)

          if !groundingMetadata.groundingChunks.isEmpty {
            Divider()
            // Source links
            ForEach(0 ..< groundingMetadata.groundingChunks.count, id: \.self) { index in
              if let webChunk = groundingMetadata.groundingChunks[index].web {
                SourceLinkView(
                  title: webChunk.title ?? "Untitled Source",
                  uri: webChunk.uri
                )
              }
            }
          }
          // Search suggestions
          if let searchEntryPoint = groundingMetadata.searchEntryPoint {
            Divider()
            WebView(htmlString: searchEntryPoint.renderedContent)
              .frame(height: 44)
              .clipShape(RoundedRectangle(cornerRadius: 22))
          }
        }
      }
      .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: .leading)
    }
  }
}

struct MessageView: View {
  var message: ChatMessage

  var body: some View {
    HStack {
      if message.participant == .user {
        Spacer()
      }
      MessageContentView(message: message)
        .padding(10)
        .background(message.participant == .system
          ? Color(UIColor.systemFill)
          : Color(UIColor.systemBlue))
        .roundedCorner(10,
                       corners: [
                         .topLeft,
                         .topRight,
                         message.participant == .system ? .bottomRight : .bottomLeft,
                       ])
      if message.participant == .system {
        Spacer()
      }
    }
    .listRowSeparator(.hidden)
  }
}

struct MessageView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      List {
        MessageView(message: ChatMessage.samples[0])
        MessageView(message: ChatMessage.samples[1])
        MessageView(message: ChatMessage.samples[2])
        MessageView(message: ChatMessage(message: "Hello!", participant: .system, pending: true))
      }
      .listStyle(.plain)
      .navigationTitle("Chat example")
    }
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

/// A view to show when a response cannot be displayed due to compliance or other errors.
struct ComplianceErrorView: View {
  var message =
    "Could not display the response because it was missing required attribution components."

  var body: some View {
    HStack {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundColor(.orange)
      Text(message)
    }
    .padding()
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}
