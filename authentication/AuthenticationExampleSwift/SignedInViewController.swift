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

//
// For more information on setting up and running this sample code, see
// https://developers.google.com/firebase/docs/auth/ios/user-auth
//

import UIKit

// [START usermanagement_view_import]
import FirebaseAuth
import Firebase.Core
// [END usermanagement_view_import]

@objc(SignedInViewController)
class SignedInViewController: UIViewController {

  /** @property userInfoProfileURLImageView
  @brief A UIImageView whose image is set to the user's profile URL.
  */
  @IBOutlet weak var userInfoProfileURLImageView:UIImageView!

  /** @property userInfoDisplayNameLabel
  @brief A UILabel whose text is set to the user's display name.
  */
  @IBOutlet weak var userInfoDisplayNameLabel:UILabel!

  /** @property userInfoEmailLabel
  @brief A UILabel whose text is set to the user's email.
  */
  @IBOutlet weak var userInfoEmailLabel:UILabel!

  /** @property userInfoUserIDLabel
  @brief A UILabel whose text is set to the user's User ID.
  */
  @IBOutlet weak var userInfoUserIDLabel:UILabel!

  /** @property userInfoProviderListLabel
  @brief A UILabel whose text is set to the user's comma-delimited list of federated sign in
  provider IDs.
  */
  @IBOutlet weak var userInfoProviderListLabel:UILabel!

  /*! @var kOKButtonText
  @brief The text of the "OK" button for the Sign In result dialogs.
  */
  let kOKButtonText = "OK"

  /*! @var kTokenRefreshedAlertTitle
  @brief The title of the "Token Refreshed" alert.
  */
  let kTokenRefreshedAlertTitle = "Token"

  /*! @var kTokenRefreshErrorAlertTitle
  @brief The title of the "Token Refresh error" alert.
  */
  let kTokenRefreshErrorAlertTitle = "Get Token Error"

  /** @var kSetDisplayNameTitle
  @brief The title of the "Set Display Name" error dialog.
  */
  let kSetDisplayNameTitle = "Set Display Name"

  /** @var kUnlinkTitle
   @brief The text of the "Unlink from Provider" error Dialog.
   */
  let kUnlinkTitle = "Unlink from Provider"

  /** @var kChangeEmailText
  @brief The title of the "Change Email" button.
  */
  let kChangeEmailText = "Change Email"

  /** @var kChangePasswordText
  @brief The title of the "Change Password" button.
  */
  let kChangePasswordText = "Change Password"


  override func viewDidLoad() {
    // Give us a circle for the image view:
    userInfoProfileURLImageView.layer.cornerRadius =
      userInfoProfileURLImageView.frame.size.width / 2.0
    userInfoProfileURLImageView.layer.masksToBounds = true
    updateUserInfo(FIRAuth.auth())
  }

  /** @fn signOut
   @brief Signs the user out.
   */
  @IBAction func didSignOut(sender: AnyObject) {
    // [START auth_signout]
    let firebaseAuth = FIRAuth.auth()
    do {
      try firebaseAuth?.signOut()
      // [START_EXCLUDE]
      performSegueWithIdentifier("SignOut", sender: nil)
      // [END_EXCLUDE]
    } catch let signOutError as NSError {
      print ("Error signing out: %@", signOutError)
    }
    // [END auth_signout]
  }

  /** @fn forceTokenRefresh
   @brief Invoked when the token refresh row is pressed.
   */
  @IBAction func didTokenRefresh(sender: AnyObject) {
    let action: FIRAuthTokenCallback = {(token, error) in
      let okAction = UIAlertAction.init(title: self.kOKButtonText, style: .Default)
        {action in print(self.kOKButtonText)}
      if let error = error {
        let alertController  = UIAlertController.init(title: self.kTokenRefreshErrorAlertTitle,
          message: error.localizedDescription, preferredStyle: .Alert)
        alertController.addAction(okAction)
        self.presentViewController(alertController, animated: true, completion: nil)
        return
      }

      // Log token refresh event to Scion.
      FIRAnalytics.logEventWithName("tokenrefresh", parameters: nil)

      let alertController = UIAlertController.init(title: self.kTokenRefreshedAlertTitle,
          message: token, preferredStyle: .Alert)
        alertController.addAction(okAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    // [START token_refresh]
    FIRAuth.auth()?.currentUser?.getTokenForcingRefresh(true, callback: action)
    // [END token_refresh]
  }

  /** @fn setDisplayName
  @brief Changes the display name of the current user.
  */
  @IBAction func didSetDisplayName(sender: AnyObject) {
    showTextInputPromptWithMessage("Display Name:") { (userPressedOK, userInput) in
      if (userPressedOK != true) || userInput!.isEmpty {
        return
      }

      self.showSpinner({
        // [START profile_change]
        let changeRequest = FIRAuth.auth()?.currentUser?.profileChangeRequest()
        changeRequest?.displayName = userInput!
        changeRequest?.commitChangesWithCallback() { (error) in
          // [END profile_change]
          self.hideSpinner({
            self.showTypicalUIForUserUpdateResultsWithTitle(self.kSetDisplayNameTitle, error: error)
            //self.updateUserInfo(FIRAuth.auth())
          })
        }
      })
    }
  }


  @IBAction func didUnlinkFacebook(sender: AnyObject) {
    unlinkFromProvider(FIRFacebookAuthProviderID)
  }

  @IBAction func didUnlinkGoogle(sender: AnyObject) {
    unlinkFromProvider(FIRGoogleAuthProviderID)
  }

  /** @fn unlinkFromProvider:
  @brief Unlinks the current user from the provider with the specified provider ID.
  @param provider The provider ID of the provider to unlink the current user's account from.
  */
  func unlinkFromProvider(provider: String) {
    // [START unlink_provider]
    FIRAuth.auth()?.currentUser?.unlinkFromProvider(provider) { (user, error) in
      self.showTypicalUIForUserUpdateResultsWithTitle(self.kUnlinkTitle, error: error)
      //self.updateUserInfo(FIRAuth.auth())
    }
    // [END unlink_provider]
  }

  /** @fn requestVerifyEmail
  @brief Requests a "verify email" email be sent.
  */
  @IBAction func didRequestVerifyEmail(sender: AnyObject) {
    showSpinner({
      // [START send_verification_email]
      FIRAuth.auth()!.currentUser!.sendEmailVerification({ (error) in
        // [END send_verification_email]
        self.hideSpinner({
          if let error = error {
            self.showMessagePrompt(error.localizedDescription)
            return
          }

          self.showMessagePrompt("Sent")
        })
      })
    })
  }

  /** @fn changeEmail
  @brief Changes the email address of the current user.
  */
  @IBAction func didChangeEmail(sender: AnyObject) {
    showTextInputPromptWithMessage("Email Address:") { (userPressedOK, userInput) in
      if (userPressedOK != true) || userInput!.isEmpty {
        return
      }

      self.showSpinner({
        // [START change_email]
        FIRAuth.auth()!.currentUser!.updateEmail(userInput!) { (error) in
          // [END change_email]
          self.hideSpinner({
            self.showTypicalUIForUserUpdateResultsWithTitle(self.kChangeEmailText, error:error)
            //self.updateUserInfo(FIRAuth.auth())
          })
        }
      })
    }
  }

  /** @fn changePassword
  @brief Changes the password of the current user.
  */
  @IBAction func didChangePassword(sender: AnyObject) {
    showTextInputPromptWithMessage("New Password:") { (userPressedOK, userInput) in
      if (userPressedOK != true) || userInput!.isEmpty {
        return
      }

      self.showSpinner({
        // [START change_password]
        FIRAuth.auth()!.currentUser!.updatePassword(userInput!) { (error) in
          // [END change_password]
          self.hideSpinner({
            self.showTypicalUIForUserUpdateResultsWithTitle(self.kChangePasswordText, error:error)
            //self.updateUserInfo(FIRAuth.auth())
          })
        }
      })
    }
  }

  // MARK: - Helpers

  /** @fn showTypicalUIForUserUpdateResultsWithTitle:error:
  @brief Shows a @c UIAlertView if error is non-nil with the localized description of the error.
  @param resultsTitle The title of the @c UIAlertView
  @param error The error details to display if non-nil.
  */
  func showTypicalUIForUserUpdateResultsWithTitle(resultsTitle: String, error: NSError?) {
    if let error = error {
      let message = "\(error.domain) (\(error.code))\n\(error.localizedDescription)"
      let okAction = UIAlertAction.init(title: self.kOKButtonText, style: .Default)
        {action in print(self.kOKButtonText)}
      let alertController  = UIAlertController.init(title: resultsTitle,
        message: message, preferredStyle: .Alert)
      alertController.addAction(okAction)
      self.presentViewController(alertController, animated: true, completion: nil)
      return
    }
  }

  func updateUserInfo(auth: FIRAuth?) {
    let user = auth?.currentUser
    userInfoDisplayNameLabel.text = user?.displayName
    userInfoEmailLabel.text = user?.email
    userInfoUserIDLabel.text = user?.uid

    let providers = user?.providerData.map { userInfo in userInfo.providerID }
    userInfoProviderListLabel.text = providers?.joinWithSeparator(", ")

    let photoURL = user?.photoURL
    struct last {
      static var photoURL: NSURL? = nil
    }
    last.photoURL = photoURL;  // to prevent earlier image overwrites later one.
    if (photoURL != nil) {
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
        let image = UIImage.init(data: NSData.init(contentsOfURL: photoURL!)!)
        dispatch_async(dispatch_get_main_queue(), {
          if (photoURL == last.photoURL) {
            self.userInfoProfileURLImageView.image = image
          }
        })
      })
    } else {
      userInfoProfileURLImageView.image = nil
    }
  }
}
