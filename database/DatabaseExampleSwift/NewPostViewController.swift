//
//  Copyright (c) 2015 Google Inc.
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
import Firebase

@objc(NewPostViewController)
class NewPostViewController: UIViewController, UITextFieldDelegate {

  var ref: FIRDatabaseReference!
  @IBOutlet weak var bodyTextView: UITextView!
  @IBOutlet weak var titleTextField: UITextField!

  // UIView lifecycle methods
  override func viewDidLoad() {
    super.viewDidLoad()

    // [START create_database_reference]
    self.ref = FIRDatabase.database().reference()
    // [END create_database_reference]

    let doneBar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: 320, height: 44))
    doneBar.autoresizingMask = .FlexibleWidth
    let flex = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
    let done = UIBarButtonItem(title: "Post", style: .Plain, target: self, action: #selector(didTapShare))
    done.tintColor = UIColor(red: 1.0, green: 143.0/255.0, blue: 0.0, alpha: 1.0)
    doneBar.items  = [flex, done, flex]
    doneBar.sizeToFit()
    bodyTextView.inputAccessoryView = doneBar
    titleTextField.inputAccessoryView = doneBar
  }

  @IBAction func didTapShare(sender: AnyObject) {
    // [START single_value_read]
    let userID = FIRAuth.auth()?.currentUser?.uid
    ref.child("users").child(userID!).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
      // Get user value
      let username = snapshot.value!["username"] as! String
      let user = User.init(username: username)

      // [START_EXCLUDE]
      // Write new post
      self.writeNewPost(userID!, username: user.username, title: self.titleTextField.text!, body: self.bodyTextView.text)
      // Finish this Activity, back to the stream
      self.navigationController?.popViewControllerAnimated(true)
      // [END_EXCLUDE]
      }) { (error) in
        print(error.localizedDescription)
    }
    // [END single_value_read]
  }

  func writeNewPost(userID: String, username: String, title: String, body: String) {
    // Create new post at /user-posts/$userid/$postid and at
    // /posts/$postid simultaneously
    // [START write_fan_out]
    let key = ref.child("posts").childByAutoId().key
    let post = ["uid": userID,
                "author": username,
                "title": title,
                "body": body]
    let childUpdates = ["/posts/\(key)": post,
                        "/user-posts/\(userID)/\(key)/": post]
    ref.updateChildValues(childUpdates)
    // [END write_fan_out]
  }

  func textFieldShouldReturn(textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return false
  }
}
