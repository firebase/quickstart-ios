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
import FirebaseApp
import Firebase.Auth
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
    let app = FIRFirebaseApp.app()
    storageRef = FIRStorage.storage(app: app!).reference
    // [END configurestorage]

    // [START storageauth]
    // Using Firebase Storage requires the user be authenticated. Here we are using
    // anonymous authentication.
    if (FIRAuth.auth()?.currentUser == nil) {
      FIRAuth.auth()?.signInAnonymouslyWithCallback({ (user:FIRUser?, error:NSError?) in
        if (error != nil) {
          self.urlTextView.text = error?.description
          self.takePicButton.enabled = false
          self.downloadPicButton.enabled = false
        } else {
          self.urlTextView.text = ""
          self.takePicButton.enabled = true
          self.downloadPicButton.enabled = true
        }
      })
    }
    // [END storageauth]
  }

  // MARK: - Image Picker

  @IBAction func didTapTakePicture(_: AnyObject) {
    let picker = UIImagePickerController()
    picker.delegate = self
    if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)) {
      picker.sourceType = UIImagePickerControllerSourceType.Camera
    } else {
      picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
    }

    presentViewController(picker, animated: true, completion:nil)
  }

  func imagePickerController(picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [String : AnyObject]) {
      picker.dismissViewControllerAnimated(true, completion:nil)

    urlTextView.text = "Beginning Upload";
    let referenceUrl = info[UIImagePickerControllerReferenceURL] as! NSURL
    if #available(iOS 8.0, *) {
      let assets = PHAsset.fetchAssetsWithALAssetURLs([referenceUrl], options: nil)
      let asset = assets.firstObject
      asset?.requestContentEditingInputWithOptions(nil, completionHandler: { (contentEditingInput, info) in
        let imageFile = contentEditingInput?.fullSizeImageURL?.absoluteString
        let filePath = "\(FIRAuth.auth()?.currentUser?.uid)/\(Int(NSDate.timeIntervalSinceReferenceDate() * 1000))/\(referenceUrl.lastPathComponent!)"
        // [START uploadimage]
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpeg"
        self.storageRef.childByAppendingPath(filePath)
          .putFile(imageFile!, metadata: metadata) { (metadata, error) in
            if let error = error {
              print("Error uploading: \(error)")
              self.urlTextView.text = "Upload Failed"
              return
            }
            print("Upload Succeeded!")
            self.urlTextView.text = metadata!.downloadURL()!.absoluteString
        }
        // [END uploadimage]
      })
    } else {
      // Fallback on earlier versions
    }
  }

  func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    picker.dismissViewControllerAnimated(true, completion:nil)
  }
}