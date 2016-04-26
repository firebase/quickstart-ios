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

import TwitterKit
import FirebaseAuth

@objc(TwitterLoginViewController)
class TwitterLoginViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    let logInButton = TWTRLogInButton(logInCompletion: { session, error in
      if let session = session {
        // [START headless_twitter_auth]
        let credential = FIRTwitterAuthProvider.credentialWithToken(session.authToken, secret:session.authTokenSecret)

        // [START_EXCLUDE]
        self.showSpinner({
          // [END_EXCLUDE]
          FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
            // [END headless_twitter_auth]
            self.hideSpinner({
              if let error = error {
                self.showMessagePrompt(error.localizedDescription)
                return
              }
              self.performSegueWithIdentifier("TwitterLogin", sender: nil)
            })
          }
        })
      } else {
        print("error: \(error!.localizedDescription)");
      }
    })
    logInButton.center = self.view.center
    self.view.addSubview(logInButton)
  }
}
