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

      let image = info[UIImagePickerControllerOriginalImage] as! UIImage,
          imageData = UIImageJPEGRepresentation(image, 0.8)

      urlTextView.text = "Beginning Upload";

      // [START uploadimage]
      let metadata = FIRStorageMetadata()
      metadata.contentType = "image/jpeg"
      let upload:FIRStorageUploadTask = storageRef.childByAppendingPath("myimage.jpg")
                          .putData(imageData!, metadata: metadata)
      // [END uploadimage]

      // [START oncomplete]
      upload.observeStatus(.Success, withCallback: { (task) in
        self.urlTextView.text = "Upload Succeeded!"
        self.onSuccessfulUpload()
      })
      // [END oncomplete]

      // [START onfailure]
      upload.observeStatus(.Failure) { (task, error) in
        if let error = error {
          print("Error uploading: \(error.description)")
        }
        self.urlTextView.text = "Upload Failed"
      }
      // [END onfailure]
  }

  func onSuccessfulUpload () {
    print("Retrieving metadata")
    urlTextView.text = "Fetching Metadata"
    // [START getmetadata]
    storageRef.childByAppendingPath("myimage.jpg").downloadURLWithCompletion({ (url:NSURL?, error:NSError?) in
      if let error = error {
        print("Error retrieving download URL: \(error)")
        self.urlTextView.text = "Error fetching download URL"
        return;
      }
      self.urlTextView.text = url!.absoluteString
    });
    // [END getmetadata]
  }

  func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    picker.dismissViewControllerAnimated(true, completion:nil)
  }
}