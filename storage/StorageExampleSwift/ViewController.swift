//
//  Copyright (c) 2016 Google Inc.
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

import UIKit
import Photos
import Firebase
import FirebaseStorageSwift

@objc(ViewController)
class ViewController: UIViewController,
                      UIImagePickerControllerDelegate, UINavigationControllerDelegate {

  @IBOutlet weak var takePicButton: UIButton!
  @IBOutlet weak var downloadPicButton: UIButton!
  @IBOutlet weak var urlTextView: UITextField!

  // [START configurestorage]
  lazy var storage = Storage.storage()
  // [END configurestorage]

  override func viewDidLoad() {
    super.viewDidLoad()

    // [START storageauth]
    // Using Cloud Storage for Firebase requires the user be authenticated. Here we are using
    // anonymous authentication.
    if Auth.auth().currentUser == nil {
      Auth.auth().signInAnonymously(completion: { (authResult, error) in
        if let error = error {
          self.urlTextView.text = error.localizedDescription
          self.takePicButton.isEnabled = false
        } else {
          self.urlTextView.text = ""
          self.takePicButton.isEnabled = true
        }
      })
    }
    // [END storageauth]
  }

  // MARK: - Image Picker

  @IBAction func didTapTakePicture(_: AnyObject) {
    let picker = UIImagePickerController()
    picker.delegate = self
    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      picker.sourceType = .camera
    } else {
      picker.sourceType = .photoLibrary
    }

    present(picker, animated: true, completion:nil)
  }

  func imagePickerController(_ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

      picker.dismiss(animated: true, completion:nil)

    urlTextView.text = "Beginning Upload"
    // if it's a photo from the library, not an image from the camera
    if let referenceUrl = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.referenceURL)] as? URL {
      let assets = PHAsset.fetchAssets(withALAssetURLs: [referenceUrl], options: nil)
      let asset = assets.firstObject
      asset?.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, info) in
        let imageFile = contentEditingInput?.fullSizeImageURL
        let filePath = Auth.auth().currentUser!.uid +
          "/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\(imageFile!.lastPathComponent)"
        // [START uploadimage]
        let storageRef = self.storage.reference(withPath: filePath)
        storageRef.putFile(from: imageFile!) { result in
          switch result {
          case .success:
            self.uploadSuccess(storageRef, storagePath: filePath)
          case let .failure(error):
            print("Error uploading: \(error)")
            self.urlTextView.text = "Upload Failed"
          }
        }
        // [END uploadimage]
      })
    } else {
      guard let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage else { return }
      guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
      let imagePath = Auth.auth().currentUser!.uid +
        "/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
      let metadata = StorageMetadata()
      metadata.contentType = "image/jpeg"
      let storageRef = self.storage.reference(withPath: imagePath)
      storageRef.putData(imageData, metadata: metadata) { result in
        switch result {
        case .success:
          self.uploadSuccess(storageRef, storagePath: imagePath)
        case let .failure(error):
          print("Error uploading: \(error)")
          self.urlTextView.text = "Upload Failed"
        }
      }
    }
  }

  func uploadSuccess(_ storageRef: StorageReference, storagePath: String) {
    print("Upload Succeeded!")
    storageRef.downloadURL { result in
      switch result {
      case let .success(url):
        self.urlTextView.text = url.absoluteString
        UserDefaults.standard.set(storagePath, forKey: "storagePath")
        UserDefaults.standard.synchronize()
        self.downloadPicButton.isEnabled = true
      case let .failure(error):
        print("Error getting download URL: \(error)")
        self.urlTextView.text = "Can't get download URL"
      }
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true, completion:nil)
  }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
