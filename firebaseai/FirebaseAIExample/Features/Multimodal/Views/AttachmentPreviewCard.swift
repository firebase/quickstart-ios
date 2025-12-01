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

import SwiftUI

private enum AttachmentType: String {
  case image, video, audio, pdf, other

  init(mimeType: String) {
    let mt = mimeType.lowercased()
    if mt.hasPrefix("image/") { self = .image }
    else if mt.hasPrefix("video/") { self = .video }
    else if mt.hasPrefix("audio/") { self = .audio }
    else if mt == "application/pdf" { self = .pdf }
    else { self = .other }
  }

  var systemImageName: String {
    switch self {
    case .image: return "photo"
    case .video: return "video"
    case .audio: return "waveform"
    case .pdf: return "doc.text"
    case .other: return "questionmark"
    }
  }

  var typeTagColor: Color {
    switch self {
    case .image: return .green
    case .video: return .purple
    case .audio: return .orange
    case .pdf: return .red
    case .other: return .blue
    }
  }

  var displayFileType: String {
    switch self {
    case .image: return "IMAGE"
    case .video: return "VIDEO"
    case .audio: return "AUDIO"
    case .pdf: return "PDF"
    case .other: return "UNKNOWN"
    }
  }
}

struct AttachmentPreviewCard: View {
  let attachment: MultimodalAttachment
  let onRemove: (() -> Void)?

  private var attachmentType: AttachmentType {
    AttachmentType(mimeType: attachment.mimeType)
  }

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: attachmentType.systemImageName)
        .font(.system(size: 20))
        .foregroundColor(.blue)
        .frame(width: 40, height: 40)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))

      VStack(alignment: .leading, spacing: 4) {
        Text(displayName)
          .font(.system(size: 14, weight: .medium))
          .lineLimit(1)
          .truncationMode(.middle)
          .foregroundColor(.primary)

        HStack(spacing: 8) {
          Text(attachmentType.displayFileType)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(attachmentType.typeTagColor)
            .foregroundColor(.white)
            .clipShape(Capsule())

          Spacer()
        }
      }

      if let onRemove = onRemove {
        Button(action: onRemove) {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 16))
            .foregroundColor(.gray)
        }
        .buttonStyle(PlainButtonStyle())
      }
    }
    .padding(12)
    .background(Color(.systemGray6))
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color(.separator), lineWidth: 0.5)
    )
  }

  private var displayName: String {
    let fileName = attachment.url?.lastPathComponent ?? "Default"
    let maxLength = 30
    if fileName.count <= maxLength {
      return fileName
    }

    let prefixName = fileName.prefix(15)
    let suffixName = fileName.suffix(10)
    return "\(prefixName)...\(suffixName)"
  }
}

struct AttachmentPreviewScrollView: View {
  let attachments: [MultimodalAttachment]
  var onAttachmentRemove: ((MultimodalAttachment) -> Void)? = nil

  var body: some View {
    if !attachments.isEmpty {
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(spacing: 8) {
          ForEach(attachments) { attachment in
            AttachmentPreviewCard(
              attachment: attachment,
              onRemove: onAttachmentRemove == nil ? nil : { onAttachmentRemove?(attachment) }
            )
            .frame(width: 180)
          }
        }
        .padding(.horizontal, 16)
      }
      .frame(height: 80)
    } else {
      EmptyView()
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    AttachmentPreviewCard(
      attachment: MultimodalAttachment(
        mimeType: "image/jpeg",
        data: Data()
      ),
      onRemove: { print("Image removed") }
    )

    AttachmentPreviewCard(
      attachment: MultimodalAttachment(
        mimeType: "application/pdf",
        data: Data()
      ),
      onRemove: { print("PDF removed") }
    )

    AttachmentPreviewCard(
      attachment: MultimodalAttachment(
        mimeType: "video/mp4",
        data: Data()
      ),
      onRemove: { print("Video removed") }
    )

    AttachmentPreviewCard(
      attachment: MultimodalAttachment(
        mimeType: "audio/mpeg",
        data: Data()
      ),
      onRemove: { print("Audio removed") }
    )
  }
  .padding()
}
