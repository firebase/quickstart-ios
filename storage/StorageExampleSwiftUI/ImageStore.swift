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

import Firebase
import FirebaseStorageSwift

/// ImageStore facilitates saving and loading an image.
public class ImageStore: ObservableObject {
  /// Reference to Firebase storage.
  private var storage: Storage

  /// Quality for JPEG images where 1.0 is the best quality and 0.0 is the worst.
  public var compressionQuality: CGFloat = 0.8

  /// UserDefaults key that will have a value containing the path of the last image.
  public let imagePathKey = "imagePath"

  /// Binds to the current image.
  @Published var image: UIImage?

  lazy var localImageFileDirectory: String = {
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    let documentsDirectory = paths[0]
    return "file:\(documentsDirectory)"
  }()

  public init(storage: Storage) {
    self.storage = storage
  }

  /// Saves an image in the store.
  /// - Parameter image: The image to save.
  public func saveImage(_ image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
    self.image = image
    let imagePath = "\(Auth.auth().currentUser!.uid)/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
    uploadImage(image, atPath: imagePath) { result in
      UserDefaults.standard.setValue(imagePath, forKey: self.imagePathKey)
      completion(result)
    }
  }

  /// Loads the most recent image.
  public func loadImage() {
    if let imagePath = UserDefaults.standard.string(forKey: imagePathKey) {
      downloadImage(atPath: imagePath)
    }
  }

  /// Uploads an image to Firebase storage.
  /// - Parameters:
  ///   - image: Image to upload.
  ///   - imagePath: Path of the image in Firebase storage.
  private func uploadImage(
    _ image: UIImage,
    atPath imagePath: String,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    guard let imageData = image.jpegData(compressionQuality: compressionQuality) else { return }

    let imageMetadata = StorageMetadata()
    imageMetadata.contentType = "image/jpeg"

    let storageRef = storage.reference(withPath: imagePath)
    storageRef.putData(imageData, metadata: imageMetadata) { result in
      switch result {
      case .success:
        completion(.success(()))
      case let .failure(error):
        completion(.failure(error))
        break
      }
    }
  }

  /// Downloads an image from Firebase storage.
  /// - Parameter imagePath: Path of the image in Firebase storage.
  private func downloadImage(atPath imagePath: String) {
    guard let imageURL = URL(string: "\(self.localImageFileDirectory)/\(imagePath)") else { return }
    self.storage.reference().child(imagePath).write(toFile: imageURL) { result in
      switch result {
      case let .success(downloadedFileURL):
        self.image = UIImage(contentsOfFile: downloadedFileURL.path)
      case let .failure(error):
        print("Error downloading: \(error)")
      }
    }
  }
}
