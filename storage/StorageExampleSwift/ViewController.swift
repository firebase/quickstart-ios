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
import FirebaseAuth
import FirebaseStorage
/* Note that "#import "FirebaseStorage.h" is included in BridgingHeader.h */

@objc(ViewController)
class ViewController: UIViewController,
                      UIImagePickerControllerDelegate, UINavigationControllerDelegate {

  @IBOutlet weak var takePicButton:UIButton!
  @IBOutlet weak var downloadPicButton:UIButton!
  @IBOutlet weak var urlTextView:UITextField!

  var storageRef:FIRStorageReference!


  override func viewDidLoad() {
    super.viewDidLoad()

    // [START configurestorage]
    storageRef = FIRStorage.storage().reference()
    // [END configurestorage]

    // [START storageauth]
    // Using Firebase Storage requires the user be authenticated. Here we are using
    // anonymous authentication.
    if (FIRAuth.auth()?.currentUser == nil) {
      FIRAuth.auth()?.signInAnonymously(completion: { (user: FIRUser?, error: Error?) in
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
    if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
      picker.sourceType = .camera
    } else {
      picker.sourceType = .photoLibrary
    }

    present(picker, animated: true, completion:nil)
  }

  func imagePickerController(_ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [String : Any]) {
      picker.dismiss(animated: true, completion:nil)

    urlTextView.text = "Beginning Upload";
    // if it's a photo from the library, not an image from the camera
    if #available(iOS 8.0, *), let referenceUrl = info[UIImagePickerControllerReferenceURL] {
      let assets = PHAsset.fetchAssets(withALAssetURLs: [referenceUrl as! URL], options: nil)
      let asset = assets.firstObject
      asset?.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput,info) in
        let imageFile = contentEditingInput?.fullSizeImageURL
        let filePath = FIRAuth.auth()!.currentUser!.uid +
          "/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\(imageFile!.lastPathComponent)"
        // [START uploadimage]
        self.storageRef.child(filePath)
          .putFile(imageFile!, metadata: nil) { (metadata, error) in
            if let error = error {
              print("Error uploading: \(error)")
              self.urlTextView.text = "Upload Failed"
              return
            }
            self.uploadSuccess(metadata!, storagePath: filePath)
        }
        // [END uploadimage]
      })
    } else {
      let image = info[UIImagePickerControllerOriginalImage] as! UIImage
      let imageData = UIImageJPEGRepresentation(image, 0.8)
      let imagePath = FIRAuth.auth()!.currentUser!.uid +
        "/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
      let metadata = FIRStorageMetadata()
      metadata.contentType = "image/jpeg"
      self.storageRef.child(imagePath)
        .put(imageData!, metadata: metadata) { (metadata, error) in
          if let error = error {
            print("Error uploading: \(error)")
            self.urlTextView.text = "Upload Failed"
            return
          }
          self.uploadSuccess(metadata!, storagePath: imagePath)
        }
    }
  }

  func uploadSuccess(_ metadata: FIRStorageMetadata, storagePath: String) {
    print("Upload Succeeded!")
    self.urlTextView.text = metadata.downloadURL()!.absoluteString
    UserDefaults.standard.set(storagePath, forKey: "storagePath")
    UserDefaults.standard.synchronize()
    self.downloadPicButton.isEnabled = true
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true, completion:nil)
  }
}
