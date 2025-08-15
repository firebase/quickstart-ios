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
#if canImport(FirebaseAILogic)
  import FirebaseAILogic
#else
  import FirebaseAI
#endif

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
  @Environment(\.presentErrorAction) var presentErrorAction
  var message: ChatMessage

  var body: some View {
    if message.pending {
      BouncingDots()
    } else {
      // Error Message
      if let error = message.error {
        HStack {
          Text("An error occurred.")
          Button("More information", systemImage: "info.circle") {
            presentErrorAction?(error)
          }
          .labelStyle(.iconOnly)
        }
      }

      // Grounded Response
      else if let groundingMetadata = message.groundingMetadata {
        GroundedResponseView(message: message, groundingMetadata: groundingMetadata)
      }

      // Non-grounded response
      else {
        ResponseTextView(message: message)
      }
    }
  }
}

struct ResponseTextView: View {
  var message: ChatMessage

  var body: some View {
    Markdown(message.content ?? "")
      .markdownTextStyle {
        FontFamilyVariant(.normal)
        FontSize(.em(0.85))
        ForegroundColor(message.participant == .other ? Color(UIColor.label) : .white)
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

struct MessageView: View {
  var message: ChatMessage

  private var participantLabel: String {
    message.participant == .user ? "User" : "Model"
  }

  var body: some View {
    VStack(alignment: message.participant == .user ? .trailing : .leading, spacing: 4) {
      // Sender label
      Text(participantLabel)
        .font(.caption2)
        .fontWeight(.medium)
        .foregroundColor(.secondary)
        .textCase(.uppercase)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: message.participant == .user ? .trailing : .leading)

      // Message content
      HStack {
        if message.participant == .user {
          Spacer()
        }
        MessageContentView(message: message)
          .padding(10)
          .background(message.participant == .other
            ? Color(UIColor.systemFill)
            : Color(UIColor.systemBlue))
          .roundedCorner(10,
                         corners: [
                           .topLeft,
                           .topRight,
                           message.participant == .other ? .bottomRight : .bottomLeft,
                         ])
        if message.participant == .other {
          Spacer()
        }
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
        MessageView(message: ChatMessage(content: "Hello!", participant: .other, pending: true))
      }
      .listStyle(.plain)
      .navigationTitle("Chat example")
    }
  }
}
