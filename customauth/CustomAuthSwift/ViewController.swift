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
import Firebase.Core
import FirebaseDatabase


@objc(ViewController)
class ViewController: UIViewController {

  @IBOutlet weak var signInStatus:UILabel!
  @IBOutlet weak var tokenField:UITextView!
  @IBOutlet weak var signInButton:UIButton!
  @IBOutlet weak var tokenRefreshButton:UIButton!
  var ref:Firebase!
  var auth:FIRAuth!

  override func viewDidLoad() {
    super.viewDidLoad()
    // [START init_app]
    let opts = FIRFirebaseOptions.init()
    opts.APIKey = FIRContext.sharedInstance().serviceInfo.apiKey
    opts.authWidgetURL = NSURL(string: "https://gitkitmobile.appspot.com/gitkit.jsp")
    let app =
        FIRFirebaseApp.initializedAppWithAppId(FIRContext.sharedInstance().serviceInfo.googleAppID,
        options: opts)
    auth = FIRAuth.init(forApp: app!)
    // [END init_app]
  }

  override func viewWillAppear(animated: Bool) {
    if (auth?.currentUser != nil) {
      isSignedIn();
    } else {
      isSignedOut();
    }
  }

  func isSignedIn () {
    signInStatus.text = "Signed In"
    signInButton.setTitle("Sign Out", forState: UIControlState.Normal)
    signInButton.setNeedsLayout()
  }

  func isSignedOut () {
    signInStatus.text = "Signed Out"
    signInButton.setTitle("Sign In", forState: UIControlState.Normal)
  }

  @IBAction func didTapSignIn (sender:AnyObject) {
    if (auth.currentUser != nil) {
      auth.signOut()
      isSignedOut()
      return
    }

    let customToken = tokenField.text
    // [START signinwithcustomtoken]
    auth.signInWithCustomToken(customToken) { (user:FIRUser?, err:NSError?) -> Void in
      if (err != nil) {
        print("Sign in failed: \(err)");
        // [START_EXCLUDE silent]
        self.isSignedOut()
        // [END_EXCLUDE]
        return
      }

      print("\(user?.userID) Signed In")
      // [START_EXCLUDE]
      self.isSignedIn()
      // Query the DB - we are now automatica-lly authenticated.
      self.ref = Firebase.init(url: FIRContext.sharedInstance().serviceInfo.databaseURL)
      // Note that if there are security rules on this path, the query must be issues after the
      // authentication has been established, or it will fail and the query will be cancelled.
      self.ref.observeEventType(FEventType.Value, withBlock: { (snapshot) -> Void in
        print("\(snapshot.key) -> \(snapshot.value)")
      })
      // [END_EXCLUDE]

    }
    // [END signinwithcustomtoken]
  }
}
