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

  weak var userEmailLabel:UILabel!
  weak var signOutButton:UIButton!
  weak var signInButton:UIButton!
  weak var tokenRefreshButton:UIButton!

  /*! @var kTokenRefreshButtonText
  @brief The text of the "Refresh Token" button.
  */
  var kTokenRefreshButtonText = "Get Token"

  /*! @var kTokenRefreshedAlertTitle
  @brief The title of the "Token Refreshed" alert.
  */
  var kTokenRefreshedAlertTitle = "Token"

  /*! @var kTokenRefreshErrorAlertTitle
  @brief The title of the "Token Refresh error" alert.
  */
  var kTokenRefreshErrorAlertTitle = "Get Token Error"

  /*! @var kSignInButtonText
  @brief The text of the "Sign In" button.
  */
  var kSignInButtonText = "Sign In"

  /*! @var kSignedInAlertTitle
  @brief The text of the "Sign In Succeeded" alert.
  */
  var kSignedInAlertTitle = "Signed In"

  /*! @var kSignInErrorAlertTitle
  @brief The text of the "Sign In Encountered an Error" alert.
  */
  var kSignInErrorAlertTitle = "Sign-In Error"

  /*! @var kSignOutButtonText
  @brief The text of the "Sign Out" button.
  */
  var kSignOutButtonText = "Sign Out"

  /*! @var kOKButtonText
  @brief The text of the "OK" button for the Sign In result dialogs.
  */
  var kOKButtonText = "OK"

  /*! @var kSignInButtonWidth
  @brief The width of the "Sign In" button.
  */
  var kSignInButtonWidth:CGFloat = 200

  /*! @var kSignInButtonHeight
  @brief The height of the "Sign In" button.
  */
  var kSignInButtonHeight:CGFloat = 30

  /*! @var kUserEmailLabelHeight
  @brief The height of the user's email address label.
  */
  var kUserEmailLabelHeight:CGFloat = 20

  override func loadView() {
    super.loadView()
    self.view.backgroundColor = UIColor.whiteColor()
    self.loadSignInButton()
    self.loadTokenRefreshButton()
    self.loadSignOutButton()
    self.loadUserEmailLabel()
    if let currentUser = FIRAuth.init(forApp:FIRFirebaseApp.initializedAppWithAppId(
        FIRContext.sharedInstance().serviceInfo.googleAppID)!)!.currentUser {
      userEmailLabel.text = currentUser.email
      signInButton.enabled = false
    } else {
      signOutButton.enabled = false
      tokenRefreshButton.enabled = false
    }
  }

  /*! @fn loadSignOutButton
  @brief Loads the "sign out" button.
  */
  func loadSignOutButton() {
    let signOutButton = UIButton.init(type: UIButtonType.System)
    signOutButton.frame = CGRectMake(0, 0, kSignInButtonWidth, kSignInButtonHeight)
    signOutButton.setTitle(kSignOutButtonText, forState: UIControlState.Normal)
    signOutButton.addTarget(self, action: "signOutPressed:", forControlEvents: UIControlEvents.TouchUpInside)
    signOutButton.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds) - kSignInButtonHeight)

    signOutButton.autoresizingMask =
        [.FlexibleTopMargin, .FlexibleRightMargin, .FlexibleBottomMargin, .FlexibleLeftMargin]
    self.view.addSubview(signOutButton)
    self.signOutButton = signOutButton
  }

  /*! @fn loadUserEmailLabel
  @brief Loads the label which displays the user's email address.
  */
  func loadUserEmailLabel() {
    let userEmailLabelFrame =
        CGRectMake(0, 0, self.view.bounds.size.width, kUserEmailLabelHeight)
    let userEmailLabel = UILabel.init(frame: userEmailLabelFrame)
    userEmailLabel.textAlignment = NSTextAlignment.Center
    userEmailLabel.center = self.view.center
    userEmailLabel.center =
        CGPointMake(self.view.center.x, self.view.center.y + (kSignInButtonHeight * 2))
    self.view.addSubview(userEmailLabel)
    self.userEmailLabel = userEmailLabel;
  }

  /*! @fn loadTokenRefreshButton
  @brief Loads the "refresh token" button.
  */
  func loadTokenRefreshButton() {
    let tokenRefreshButton = UIButton.init(type: UIButtonType.System)
    tokenRefreshButton.frame = CGRectMake(0, 0, kSignInButtonWidth, kSignInButtonHeight)
    tokenRefreshButton.setTitle(kTokenRefreshButtonText, forState: UIControlState.Normal)
    tokenRefreshButton.addTarget(self, action: "refreshTokenPressed:", forControlEvents: UIControlEvents.TouchUpInside)

    tokenRefreshButton.center =
        CGPointMake(CGRectGetMidX(self.view.bounds),
        CGRectGetMidY(self.view.bounds) + kSignInButtonHeight)

    tokenRefreshButton.autoresizingMask =
        [.FlexibleTopMargin, .FlexibleRightMargin, .FlexibleBottomMargin, .FlexibleLeftMargin]
    self.view.addSubview(tokenRefreshButton)
    self.tokenRefreshButton = tokenRefreshButton
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

    signInButton.autoresizingMask =
        [.FlexibleTopMargin, .FlexibleRightMargin, .FlexibleBottomMargin, .FlexibleLeftMargin]
    self.view.addSubview(signInButton)
    self.signInButton = signInButton
  }

  /*! @fn signInPressed:
  @brief Invoked when the sign in button is pressed.
  @param sender The sign in button.
  */
  func signInPressed(sender: UIButton) {
    // [START usermanagement_config]
    let firebaseAuth = FIRAuth.init(forApp:FIRFirebaseApp.initializedAppWithAppId(FIRContext.sharedInstance().serviceInfo.googleAppID)!)
    // [END usermanagement_config]
    let firebaseAuthUI:FIRAuthUI = FIRAuthUI.init(auth: firebaseAuth!, delegate: self)
    
    firebaseAuthUI.presentSignInWithCallback({(user, error) in
      if #available(iOS 8.0, *) {
        let okAction = UIAlertAction.init(title: self.kOKButtonText, style: .Default, handler: {action in print(self.kOKButtonText)})
        if ((error) != nil) {
          let alertController  = UIAlertController.init(title: self.kSignInErrorAlertTitle, message: error!.localizedDescription, preferredStyle: .Alert)
          alertController.addAction(okAction)
          self.presentViewController(alertController, animated: true, completion: nil)
          return
        }

        self.signInButton.enabled = false
        self.signOutButton.enabled = true
        self.tokenRefreshButton.enabled = true
        self.userEmailLabel.text = user!.email;

        // Log sign in event to Scion.
        GMRAppMeasurement.logEventWithName(kGMREventLogin, parameters: nil)

        let alertController = UIAlertController.init(title: self.kSignedInAlertTitle, message: user!.displayName, preferredStyle: .Alert)
        alertController.addAction(okAction)
        self.presentViewController(alertController, animated: true, completion: nil)
      } else {
          // Fallback on earlier versions
      }
    })
  }

  func signOutPressed(sender: UIButton) {
    let firebaseAuth = FIRAuth.init(forApp:FIRFirebaseApp.initializedAppWithAppId(FIRContext.sharedInstance().serviceInfo.googleAppID)!)
    firebaseAuth?.signOut()
    signInButton.enabled = true
    signOutButton.enabled = false
    tokenRefreshButton.enabled = false
    userEmailLabel.text = nil
  }

  /*! @fn refreshTokenPressed:
  @brief Invoked when the token refresh button is pressed.
  @param sender The token refresh button.
  */
  func refreshTokenPressed(sender: UIButton) {
    let firebaseAuth = FIRAuth.init(forApp:FIRFirebaseApp.initializedAppWithAppId(FIRContext.sharedInstance().serviceInfo.googleAppID)!)
    firebaseAuth!.getTokenForcingRefresh(false, withCallback: {(token, error) in
      if #available(iOS 8.0, *) {
        let okAction = UIAlertAction.init(title: self.kOKButtonText, style: UIAlertActionStyle.Default, handler: {action in print(self.kOKButtonText)})
        if ((error) != nil) {
          let alertController  = UIAlertController.init(title: self.kTokenRefreshErrorAlertTitle, message: error!.localizedDescription, preferredStyle: .Alert)
          alertController.addAction(okAction)
          self.presentViewController(alertController, animated: true, completion: nil)
          return
        }

        // Log sign in event to Scion.
        GMRAppMeasurement.logEventWithName("tokenrefresh", parameters: nil)

        let alertController = UIAlertController.init(title: self.kTokenRefreshedAlertTitle, message: token, preferredStyle: .Alert)
        alertController.addAction(okAction)
        self.presentViewController(alertController, animated: true, completion: nil)
      } else {
        // Fallback on earlier versions
      }
    })
  }
}
