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

@objc(ViewController)
class ViewController: UIViewController, FIRAuthUIDelegate {

  /*! @var kSignInButtonText
  @brief The text of the "Sign In" button.
  */
  var kSignInButtonText = "Sign In";

  /*! @var kSignedInAlertTitle
  @brief The text of the "Sign In Succeeded" alert.
  */
  var kSignedInAlertTitle = "Signed In";

  /*! @var kSignInErrorAlertTitle
  @brief The text of the "Sign In Encountered an Error" alert.
  */
  var kSignInErrorAlertTitle = "Sign-In Error";

  /*! @var kOKButtonText
  @brief The text of the "OK" button for the Sign In result dialogs.
  */
  var kOKButtonText = "OK";

  /*! @var kSignInButtonWidth
  @brief The width of the "Sign In" button.
  */
  var kSignInButtonWidth:CGFloat = 200;

  /*! @var kSignInButtonHeight
  @brief The height of the "Sign In" button.
  */
  var kSignInButtonHeight:CGFloat = 30;

  override func loadView() {
    super.loadView()
    self.view.backgroundColor = UIColor.whiteColor()
    self.loadSignInButton()
  }

  /*! @fn loadSignInButton
  @brief Loads the sign in button.
  */
  func loadSignInButton() {
    let signInButton = UIButton.init(type: UIButtonType.System)
    signInButton.frame = CGRectMake(0, 0, kSignInButtonWidth, kSignInButtonHeight)
    signInButton.setTitle(kSignInButtonText, forState: UIControlState.Normal)
    signInButton.addTarget(self, action: "signInPressed:", forControlEvents: UIControlEvents.TouchUpInside)
    signInButton.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds))

    signInButton.autoresizingMask = [UIViewAutoresizing.FlexibleTopMargin, UIViewAutoresizing.FlexibleRightMargin, UIViewAutoresizing.FlexibleBottomMargin, UIViewAutoresizing.FlexibleLeftMargin]
    self.view.addSubview(signInButton)
  }

  /*! @fn signInPressed:
  @brief Invoked when the sign in button is pressed.
  @param sender The sign in button.
  */
  func signInPressed(sender: UIButton) {
    let firebaseAuth = FIRAuth.init(forApp:FIRFirebaseApp.initializedAppWithAppId(FIRContext.sharedInstance().serviceInfo.googleAppID)!)
    let authUIOptions = FIRAuthUIOptions()
    let googleSignIn = FIRGoogleSignInAuthProvider(clientId: FIRContext.sharedInstance().serviceInfo.clientID)
    authUIOptions.addProvider(googleSignIn!)
    let firebaseAuthUI:FIRAuthUI = FIRAuthUI.init(auth: firebaseAuth!, options: authUIOptions, delegate: self)
    
    firebaseAuthUI.presentSignInWithCallback({(user, error) in
      if #available(iOS 8.0, *) {
        let okAction = UIAlertAction.init(title: self.kOKButtonText, style: UIAlertActionStyle.Default, handler: {action in print(self.kOKButtonText)})
        if ((error) != nil) {
          let alertController  = UIAlertController.init(title: self.kSignInErrorAlertTitle, message: error!.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
          alertController.addAction(okAction)
          self.presentViewController(alertController, animated: true, completion: nil)
          return
        }

        // Log sign in event to Scion.
        GMRAppMeasurement.logEventWithName(kGMREventLogin, parameters: nil)

        let alertController = UIAlertController.init(title: self.kSignedInAlertTitle, message: user!.displayName, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(okAction)
        self.presentViewController(alertController, animated: true, completion: nil)
      } else {
          // Fallback on earlier versions
      }
    })
  }
}
