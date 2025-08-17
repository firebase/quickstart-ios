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

import Foundation
import SwiftUI
import PhotosUI
import FirebaseAI

public enum AttachmentType: String, CaseIterable {
  case image = "IMAGE"
  case video = "VIDEO"
  case audio = "AUDIO"
  case pdf = "PDF"
  case link = "LINK"
  case unknown = "UNKNOWN"
}

public enum AttachmentLoadingState {
  case idle
  case loading
  case loaded
  case failed(Error)
}

public struct MultimodalAttachment: Identifiable, Equatable {
  public let id = UUID()
  public let type: AttachmentType
  public let fileName: String
  public let mimeType: String
  public let data: Data
  public let url: URL?
  public let thumbnailImage: UIImage?
  public var loadingState: AttachmentLoadingState = .idle

  public static func == (lhs: MultimodalAttachment, rhs: MultimodalAttachment) -> Bool {
    return lhs.id == rhs.id
  }

  public init(type: AttachmentType, fileName: String, mimeType: String, data: Data,
              url: URL? = nil, thumbnailImage: UIImage? = nil) {
    self.type = type
    self.fileName = fileName
    self.mimeType = mimeType
    self.data = data
    self.url = url
    self.thumbnailImage = thumbnailImage
  }

  public static func fromPhotosPickerItem(_ item: PhotosPickerItem) async -> MultimodalAttachment? {
    do {
      guard let data = try await item.loadTransferable(type: Data.self) else {
        print("Failed to create attachment from PhotosPickerItem: no data returned")
        return nil
      }

      if let image = UIImage(data: data) {
        return MultimodalAttachment(
          type: .image,
          fileName: "Local Image",
          mimeType: "image/jpeg",
          data: data,
          thumbnailImage: image
        )
      } else {
        return MultimodalAttachment(
          type: .video,
          fileName: "Local Video",
          mimeType: "video/mp4",
          data: data
        )
      }
    } catch {
      print("Failed to create attachment from PhotosPickerItem: \(error)")
      return nil
    }
  }

  public static func fromFilePickerItem(from url: URL) async -> MultimodalAttachment? {
    do {
      let data = try await Task.detached(priority: .utility) {
        try Data(contentsOf: url)
      }.value
      let fileName = url.lastPathComponent
      let mimeType = Self.getMimeType(for: url)
      let fileType = Self.getAttachmentType(for: mimeType)
      return MultimodalAttachment(
        type: fileType,
        fileName: fileName,
        mimeType: mimeType,
        data: data,
        url: url
      )
    } catch {
      print("Failed to create attachment from file at \(url): \(error)")
      return nil
    }
  }

  public static func fromURL(_ url: URL, mimeType: String) async -> MultimodalAttachment? {
    do {
      var data: Data
      data = try await Task.detached(priority: .utility) {
        try Data(contentsOf: url)
      }.value
      return MultimodalAttachment(
        type: .link,
        fileName: url.lastPathComponent,
        mimeType: mimeType,
        data: data,
        url: url
      )
    } catch {
      print("Failed to create attachment from url \(url): \(error)")
      return nil
    }
  }

  public func toInlineDataPart() -> InlineDataPart? {
    guard !data.isEmpty else { return nil }
    return InlineDataPart(data: data, mimeType: mimeType)
  }

  private static func getMimeType(for url: URL) -> String {
    let fileExtension = url.pathExtension.lowercased()

    switch fileExtension {
    // Documents / text
    case "pdf":
      return "application/pdf"
    case "txt", "text":
      return "text/plain"

    // Images
    case "jpg", "jpeg":
      return "image/jpeg"
    case "png":
      return "image/png"
    case "webp":
      return "image/webp"

    // Video
    case "flv":
      return "video/x-flv"
    case "mov", "qt":
      return "video/quicktime"
    case "mpeg":
      return "video/mpeg"
    case "mpg":
      return "video/mpg"
    case "ps":
      return "video/mpegps"
    case "mp4":
      return "video/mp4"
    case "webm":
      return "video/webm"
    case "wmv":
      return "video/wmv"
    case "3gp", "3gpp":
      return "video/3gpp"

    // Audio
    case "aac":
      return "audio/aac"
    case "flac":
      return "audio/flac"
    case "mp3":
      return "audio/mpeg"
    case "m4a":
      return "audio/m4a"
    case "mpga":
      return "audio/mpga"
    case "mp4a":
      return "audio/mp4"
    case "opus":
      return "audio/opus"
    case "pcm", "raw":
      return "audio/pcm"
    case "wav":
      return "audio/wav"
    case "weba":
      return "audio/webm"

    default:
      return "application/octet-stream"
    }
  }

  private static func getAttachmentType(for mimeType: String) -> AttachmentType {
    if mimeType.starts(with: "image/") {
      return .image
    } else if mimeType.starts(with: "video/") {
      return .video
    } else if mimeType.starts(with: "audio/") {
      return .audio
    } else if mimeType == "application/pdf" {
      return .pdf
    } else {
      return .unknown
    }
  }
}
