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

// [START auth_view_import]
import FirebaseAuth
// [END auth_view_import]

@objc(CustomTokenViewController)
class CustomTokenViewController: UIViewController {

  @IBOutlet weak var tokenField: UITextView!

  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    self.view.endEditing(true)
  }

  @IBAction func didTapCustomTokenLogin(sender: AnyObject) {
    let customToken = tokenField.text
    showSpinner({
      // [START signinwithcustomtoken]
      FIRAuth.auth()?.signInWithCustomToken(customToken) { (user, error) in
        // [START_EXCLUDE]
        self.hideSpinner({
          if let error = error {
            self.showMessagePrompt(error.localizedDescription)
            return
          }
          self.navigationController!.popViewControllerAnimated(true)
        })
        // [END_EXCLUDE]
      }
      // [END signinwithcustomtoken]
    })
  }

}
