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
class NewPostViewController: UIViewController {

  var ref: FIRDatabaseReference!
  @IBOutlet weak var bodyTextView: UITextView!
  @IBOutlet weak var titleTextField: UITextField!

  // UIView lifecycle methods
  override func viewDidLoad() {
    super.viewDidLoad()

    // [START create_database_reference]
    self.ref = FIRDatabase().reference()
    // [END create_database_reference]
  }

  @IBAction func didTapShare(sender: AnyObject) {
    let userID = FIRAuth.auth()?.currentUser?.uid
    ref.child("users").child(userID!).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
      // Get user value
      let username = snapshot.value!["username"] as! String
      let user = User.init(username: username)

      // [START_EXCLUDE]
      // Write new post
      self.writeNewPost(userID!, username: user.username, title: self.titleTextField.text!, body: self.bodyTextView.text)
      // Finish this Activity, back to the stream
      self.tabBarController!.selectedIndex = 0
      // [END_EXCLUDE]
      }) { (error) in
        print(error.localizedDescription)
    }
  }

  func writeNewPost(userID: String, username: String, title: String, body: String) {
    // Create new post at /user-posts/$userid/$postid and at
    // /posts/$postid simultaneously
    let key = ref.child("posts").childByAutoId().key
    let post = ["uid": userID,
                "author": username,
                "title": title,
                "body": body]
    let childUpdates = ["/posts/\(key)": post,
                        "/user-posts/\(key)/": post]
    ref.updateChildValues(childUpdates)
  }
}
