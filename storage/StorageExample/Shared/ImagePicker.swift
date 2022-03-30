//
//  Copyright (c) 2022 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import PhotosUI
import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
  @Binding var image: UIImage?
  var imageURL: URL?

  class Coordinator: PHPickerViewControllerDelegate {
    var parent: ImagePicker
    @EnvironmentObject var viewModel: ViewModel

    init(_ parent: ImagePicker) {
      self.parent = parent
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
      picker.dismiss(animated: true)
      if let sheet = picker.sheetPresentationController {
        sheet.detents = [.medium()]
      }
      guard let provider = results.first?.itemProvider else { return }
      if provider.canLoadObject(ofClass: UIImage.self) {
        Task {
          do {
            if let image = try await provider.loadImage() {
              DispatchQueue.main.async {
                self.parent.image = image
              }
            }
          } catch {
            self.viewModel.errInfo = error
            self.viewModel.errorFound = true
          }
        }
        Task {
          do {
            let destURL = self.parent.imageURL!

            try await provider.getFileTempURL(
              forTypeIdentifier: UTType.image.identifier,
              destURL: destURL
            )
          } catch {
            self.viewModel.errInfo = error
            self.viewModel.errorFound = true
          }
        }
      }
    }
  }

  func makeUIViewController(context: Context) -> PHPickerViewController {
    var config = PHPickerConfiguration()
    config.filter = .images
    let picker = PHPickerViewController(configuration: config)
    picker.delegate = context.coordinator

    return picker
  }

  func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
}

extension NSItemProvider {
  /// Write a copy of the file's data from a temporary file, which will be
  /// deleted when the completion handler returns, to another file, which could
  /// be reused after the completion handlers returns.
  ///
  /// - Parameters:
  ///     - forTypeIdendifier: A string that represents the desired UTI.
  ///     - destURL: The destination URL the temp file will be copied to.
  func getFileTempURL(forTypeIdentifier type: String, destURL: URL) async throws {
    do {
      return try await withCheckedThrowingContinuation { continuation in
        self.loadFileRepresentation(forTypeIdentifier: type) { url, error in
          if let error = error {
            continuation.resume(throwing: error)
          } else {
            do {
              if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
              }
              try FileManager.default.copyItem(at: url!, to: destURL)
              continuation.resume()
            } catch {
              print("Cannot copy item at \(url!) to \(destURL): \(error)")
            }
          }
        }
      }
    } catch {
      print("Cannot load file from the image picker.")
    }
  }

  func loadImage() async throws -> UIImage? {
    do {
      return try await withCheckedThrowingContinuation { continuation in
        self.loadObject(ofClass: UIImage.self) { image, error in
          if let error = error {
            continuation.resume(throwing: error)
          }
          continuation.resume(returning: image as? UIImage)
        }
      }
    } catch {
      print("Image was not properly loaded.")
      return nil
    }
  }
}
