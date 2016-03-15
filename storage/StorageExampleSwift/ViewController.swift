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

  @IBOutlet weak var emailField:UITextField!
  @IBOutlet weak var passwordField:UITextField!
  @IBOutlet weak var signinButton:UIButton!
  @IBOutlet weak var signUpButton:UIButton!
  @IBOutlet weak var takePicButton:UIButton!
  @IBOutlet weak var downloadPicButton:UIButton!
  @IBOutlet weak var urlTextView:UITextField!

  var storageRef:FIRStorageReference!


  override func viewDidLoad() {
    super.viewDidLoad()
    updateUIForUser(FIRAuth.auth()?.currentUser)

    // [START configurestorage]
    let app = FIRFirebaseApp.app()
    storageRef = FIRStorage.storage(app: app!).reference
    // [END configurestorage]
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
    storageRef.childByAppendingPath("myimage.jpg").metadataWithCompletion { (metadata, error) in
      if let error = error {
        print("Error retrieving metadata: \(error)")
        self.urlTextView.text = "Error fetching metadata"
        return;
      }
      // Get first download URL to display.
      self.urlTextView.text = metadata!.downloadURLs![0].absoluteString
    }
    // [END getmetadata]
  }

  func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    picker.dismissViewControllerAnimated(true, completion:nil)
  }


  // MARK: - Sign In

  @IBAction func didTapSignIn(_: AnyObject) {
    if (FIRAuth.auth()?.currentUser != nil) {
      // Sign out.
      do {
        try FIRAuth.auth()?.signOut()
      } catch let signOutError as NSError {
        print ("Error signing out: %@", signOutError)
      }
      updateUIForUser(FIRAuth.auth()?.currentUser)
      return
    }


    let email = emailField.text, password = passwordField.text
    FIRAuth.auth()?.signInWithEmail(email!, password: password!,
        callback: { (user:FIRUser?, error:NSError?) -> Void in
          if let error = error {
            print("Error with sign in: \(error.description)")
            self.urlTextView.text = error.description
          }
          self.updateUIForUser(user)
    })
  }

  @IBAction func didTapSignUp(_: AnyObject) {
    let email = emailField.text, password = passwordField.text
    FIRAuth.auth()?.createUserWithEmail(email!, password: password!,
        callback: { (user:FIRUser?, error:NSError?) -> Void in
      self.updateUIForUser(user)
    })
  }

  func updateUIForUser(user: FIRUser?) {
    if (user != nil) {
      emailField.enabled = false
      passwordField.enabled = false
      emailField.text = ""
      passwordField.text = "";
      signinButton.setTitle("Sign Out", forState: UIControlState.Normal)
      signUpButton.enabled = false
      takePicButton.enabled = true
      downloadPicButton.enabled = true
      urlTextView.text = ""
    } else {
      emailField.enabled = true
      passwordField.enabled = true
      signinButton.setTitle("Sign In", forState: UIControlState.Normal)
      signUpButton.enabled = true
      takePicButton.enabled = false
      downloadPicButton.enabled = false
      urlTextView.text = ""
    }
  }
}