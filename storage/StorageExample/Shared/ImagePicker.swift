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
#if os(iOS)
  import PhotosUI
#endif
import SwiftUI

#if os(iOS)
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
                continuation.resume(throwing: error)
              }
            }
          }
        }
      } catch {
        print("Cannot load file from the image picker.")
        throw error
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
        throw error
      }
    }
  }

#elseif os(macOS)

  struct ImagePicker: View {
    @Binding var image: NSImage?
    var imageURL: URL?

    var body: some View {
      ZStack {
        if let image = self.image {
          Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
        } else {
          ZStack {
            Image(systemName: "photo.fill")
              .resizable()
              .scaledToFit()
              .opacity(0.6)
              .frame(width: 300, height: 200, alignment: .top)
              .cornerRadius(16)
              .padding(.horizontal)
            Text("Drag and drop an image file")
              .frame(width: 300)
          }
        }
      }
      .frame(height: 320)
      .background(Color.black.opacity(0.6))
      .cornerRadius(16)
      .onDrop(of: ["public.url", "public.file-url"], isTargeted: nil) { (items) -> Bool in
        if let item = items.first {
          if let identifier = item.registeredTypeIdentifiers.first {
            Task {
              if identifier == "public.url" || identifier == "public.file-url" {
                do {
                  let urlData = try await item.loadItem(forTypeIdentifier: identifier)
                  if let data = urlData as? Data {
                    let url = NSURL(
                      absoluteURLWithDataRepresentation: data,
                      relativeTo: nil
                    ) as URL
                    Task { @MainActor in
                      if let image = NSImage(contentsOf: url) {
                        self.image = image
                      }
                    }
                    if let imageURL = imageURL {
                      do {
                        if FileManager.default.fileExists(atPath: imageURL.path) {
                          try FileManager.default.removeItem(at: imageURL)
                        }
                        try FileManager.default.copyItem(at: url, to: imageURL)
                        print("Image is copied from \n \(url) to \(imageURL)")
                      } catch {
                        print("Cannot copy item at \(url) to \(imageURL): \(error)")
                      }
                    }
                  }
                } catch {
                  throw error
                }
              }
            }
          }
          return true
        } else {
          print("Item not found")
          return false
        }
      }
    }
  }

#endif
