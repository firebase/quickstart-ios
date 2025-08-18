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

// MultimodalAttachment is a struct used for transporting data between ViewModels and AttachmentPreviewCard
public struct MultimodalAttachment: Identifiable, Equatable {
  public let id = UUID()
  public let mimeType: String
  public let data: Data?
  public let url: URL?

  public static func == (lhs: MultimodalAttachment, rhs: MultimodalAttachment) -> Bool {
    return lhs.id == rhs.id
  }

  public init(mimeType: String, data: Data? = nil, url: URL? = nil) {
    self.mimeType = mimeType
    self.data = data
    self.url = url
  }

  public init(fileDataPart: FileDataPart) {
    mimeType = fileDataPart.mimeType
    data = nil
    url = URL(string: fileDataPart.uri)
  }

  public static func fromPhotosPickerItem(_ item: PhotosPickerItem) async -> MultimodalAttachment? {
    do {
      guard let data = try await item.loadTransferable(type: Data.self) else {
        print("Failed to create attachment from PhotosPickerItem: no data returned")
        return nil
      }

      let mimeType = UIImage(data: data) != nil ? "image/jpg" : "video/mp4"

      return MultimodalAttachment(
        mimeType: mimeType,
        data: data
      )
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

      let mimeType = Self.getMimeType(for: url)

      return MultimodalAttachment(
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
      let data = try await Task.detached(priority: .utility) {
        try Data(contentsOf: url)
      }.value

      return MultimodalAttachment(
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
    guard let data = data, !data.isEmpty else { return nil }
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
}
