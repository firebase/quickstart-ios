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

public enum MultimodalAttachmentError: LocalizedError {
  case unsupportedFileType(extension: String)
  case noDataAvailable
  case loadingFailed(Error)
  case mimeTypeMismatch(expected: String, provided: String, extension: String)

  public var errorDescription: String? {
    switch self {
    case let .unsupportedFileType(ext):
      return "Unsupported file format: .\(ext). Please select a supported format file."
    case .noDataAvailable:
      return "File data is not available"
    case let .loadingFailed(error):
      return "File loading failed: \(error.localizedDescription)"
    case let .mimeTypeMismatch(expected, provided, ext):
      return "MIME type mismatch for .\(ext) file: expected '\(expected)', got '\(provided)'"
    }
  }
}

// MultimodalAttachment is a struct used for transporting data between ViewModels and AttachmentPreviewCard
public struct MultimodalAttachment: Identifiable, Equatable {
  public let id = UUID()
  public let mimeType: String
  public let data: Data?
  public let url: URL?
  public var isCloudStorage: Bool = false

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
    isCloudStorage = true
  }
}

// validate file type & mime type
extension MultimodalAttachment {
  public static let supportedFileExtensions: Set<String> = [
    // Documents / text
    "pdf", "txt", "text",
    // Images
    "jpg", "jpeg", "png", "webp",
    // Video
    "flv", "mov", "qt", "mpeg", "mpg", "ps", "mp4", "webm", "wmv", "3gp", "3gpp",
    // Audio
    "aac", "flac", "mp3", "m4a", "mpga", "mp4a", "opus", "pcm", "raw", "wav", "weba",
  ]

  public static func validateFileType(url: URL) throws {
    let fileExtension = url.pathExtension.lowercased()
    guard !fileExtension.isEmpty else {
      throw MultimodalAttachmentError.unsupportedFileType(extension: "No extension")
    }

    guard supportedFileExtensions.contains(fileExtension) else {
      throw MultimodalAttachmentError.unsupportedFileType(extension: fileExtension)
    }
  }

  public static func validateMimeTypeMatch(url: URL, mimeType: String) throws {
    let expectedMimeType = getMimeType(for: url)

    guard mimeType == expectedMimeType else {
      throw MultimodalAttachmentError.mimeTypeMismatch(
        expected: expectedMimeType,
        provided: mimeType,
        extension: url.pathExtension
      )
    }
  }

  public static func validatePhotoType(_ item: PhotosPickerItem) throws -> String {
    guard let fileExtension = item.supportedContentTypes.first?.preferredFilenameExtension else {
      throw MultimodalAttachmentError.unsupportedFileType(extension: "No extension")
    }

    guard supportedFileExtensions.contains(fileExtension) else {
      throw MultimodalAttachmentError.unsupportedFileType(extension: fileExtension)
    }

    guard let fileMimeType = item.supportedContentTypes.first?.preferredMIMEType else {
      throw MultimodalAttachmentError.unsupportedFileType(extension: "No MIME type")
    }

    return fileMimeType
  }
}

// load data from picker item or url
extension MultimodalAttachment {
  public static func fromPhotosPickerItem(_ item: PhotosPickerItem) async throws
    -> MultimodalAttachment {
    let fileMimeType = try validatePhotoType(item)

    do {
      guard let data = try await item.loadTransferable(type: Data.self) else {
        throw MultimodalAttachmentError.noDataAvailable
      }

      return MultimodalAttachment(
        mimeType: fileMimeType,
        data: data
      )
    } catch let error as MultimodalAttachmentError {
      throw error
    } catch {
      throw MultimodalAttachmentError.loadingFailed(error)
    }
  }

  public static func fromFilePickerItem(from url: URL) async throws -> MultimodalAttachment {
    try validateFileType(url: url)

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
      throw MultimodalAttachmentError.loadingFailed(error)
    }
  }

  public static func fromURL(_ url: URL, mimeType: String) async throws -> MultimodalAttachment {
    try validateFileType(url: url)
    try validateMimeTypeMatch(url: url, mimeType: mimeType)

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
      throw MultimodalAttachmentError.loadingFailed(error)
    }
  }

  public func toInlineDataPart() async -> InlineDataPart? {
    if let data = data, !data.isEmpty {
      return InlineDataPart(data: data, mimeType: mimeType)
    }

    // If the data is not available, try to read it from the url.
    guard let url = url else { return nil }
    do {
      let data = try await Task.detached(priority: .utility) {
        try Data(contentsOf: url)
      }.value

      guard !data.isEmpty else { return nil }
      return InlineDataPart(data: data, mimeType: mimeType)
    } catch {
      return nil
    }
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
