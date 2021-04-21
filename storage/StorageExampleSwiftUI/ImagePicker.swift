// Copyright 2021 Google LLC
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
import Firebase

/// ImagePickerRepresentable wraps a UIImagePickerController, so it is accessible through SwiftUI.
struct ImagePickerRepresentable {
  enum Source {
    case camera
    case photoLibrary
  }

  /// Denotes whether the user is taking a photo or selecting one.
  var source: Source

  /// Persistent storage which retains the image.
  @ObservedObject var store: ImageStore

  /// Binds to whether the image picker is visible.
  @Binding var visible: Bool

  /// Completion handler that is invoked when the image picker dismisses.
  var completion: () -> Void

  /// Coordinator is an internal class that acts as a delegate for the image picker.
  class Coordinator: NSObject {
    private var representable: ImagePickerRepresentable
    private var store: ImageStore

    init(representable: ImagePickerRepresentable, store: ImageStore) {
      self.representable = representable
      self.store = store
    }
  }
}

extension ImagePickerRepresentable: UIViewControllerRepresentable {
  typealias UIViewControllerType = UIImagePickerController

  /// Invoked by the system to setup a coordinator that the UIImagePickerViewController can use.
  /// - Returns: The coordinator.
  func makeCoordinator() -> Coordinator {
    Coordinator(representable: self, store: self.store)
  }

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let imagePicker = UIImagePickerController()

    switch self.source {
    case .camera:
      imagePicker.sourceType = .camera
      imagePicker.cameraCaptureMode = .photo
    case .photoLibrary:
      imagePicker.sourceType = .photoLibrary
    }

    imagePicker.delegate = context.coordinator
    return imagePicker
  }

  /// Required to implement, but unnecessary. We do not need to invalidate the SwiftUI canvas.
  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }
}

extension ImagePickerRepresentable.Coordinator: UIImagePickerControllerDelegate {
  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
  ) {
    if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
      // TODO: Consider displaying a progress bar or spinner here
      store.saveImage(image) { result in
        // TODO: Handle the error
        self.representable.visible = false
        picker.dismiss(animated: true, completion: self.representable.completion)
      }
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    self.representable.visible = false
    picker.dismiss(animated: true, completion: self.representable.completion)
  }
}

/// The coordinator must implement the UINavigationControllerDelegate protocol in order to be the
/// UIImagePickerController's delegate.
extension ImagePickerRepresentable.Coordinator: UINavigationControllerDelegate { }
