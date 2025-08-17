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

struct AttachmentPreviewCard: View {
  let attachment: MultimodalAttachment
  let onRemove: (() -> Void)?

  var body: some View {
    HStack(spacing: 12) {
      Group {
        if let thumbnailImage = attachment.thumbnailImage {
          Image(uiImage: thumbnailImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
          Image(systemName: systemImageName)
            .font(.system(size: 20))
            .foregroundColor(.blue)
            .frame(width: 40, height: 40)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(displayName)
          .font(.system(size: 14, weight: .medium))
          .lineLimit(1)
          .truncationMode(.middle)
          .foregroundColor(.primary)

        HStack(spacing: 8) {
          Text(attachment.type.rawValue)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(typeTagColor)
            .foregroundColor(.white)
            .clipShape(Capsule())

          if case .loading = attachment.loadingState {
            ProgressView()
              .scaleEffect(0.7)
              .progressViewStyle(CircularProgressViewStyle(tint: .blue))
          } else if case .failed = attachment.loadingState {
            Image(systemName: "exclamationmark.triangle.fill")
              .font(.system(size: 12))
              .foregroundColor(.red)
          }
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

  private var typeTagColor: Color {
    switch attachment.type {
    case .image:
      return .green
    case .video:
      return .purple
    case .audio:
      return .orange
    case .pdf:
      return .red
    case .link:
      return .blue
    case .unknown:
      return .gray
    }
  }

  private var systemImageName: String {
    switch attachment.type {
    case .image:
      return "photo"
    case .video:
      return "video"
    case .audio:
      return "waveform"
    case .pdf:
      return "doc.text"
    case .link:
      return "link"
    case .unknown:
      return "questionmark"
    }
  }

  private var displayName: String {
    let fileName = attachment.fileName
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
            .frame(width: 200)
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
        type: .image,
        fileName: "IMG_1234_very_long_filename_example.jpg",
        mimeType: "image/jpeg",
        data: Data(),
        thumbnailImage: UIImage(systemName: "photo"),
      ),
      onRemove: { print("Image removed") }
    )

    AttachmentPreviewCard(
      attachment: MultimodalAttachment(
        type: .pdf,
        fileName: "Document.pdf",
        mimeType: "application/pdf",
        data: Data(),
      ),
      onRemove: { print("PDF removed") }
    )

    AttachmentPreviewCard(
      attachment: {
        var attachment = MultimodalAttachment(
          type: .video,
          fileName: "video.mp4",
          mimeType: "video/mp4",
          data: Data(),
        )
        attachment.loadingState = .loading
        return attachment
      }(),
      onRemove: { print("Video removed") }
    )

    AttachmentPreviewCard(
      attachment: {
        var attachment = MultimodalAttachment(
          type: .audio,
          fileName: "audio.mp3",
          mimeType: "audio/mpeg",
          data: Data(),
        )
        attachment.loadingState = .failed(NSError(domain: "TestError", code: 1, userInfo: nil))
        return attachment
      }(),
      onRemove: { print("Audio removed") }
    )
  }
  .padding()
}
