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
import FirebaseAuthUI
import FirebaseFacebookAuthProvider
import FirebaseGoogleAuthProvider
import Firebase.Analytics
// [END usermanagement_view_import]

@objc(MainViewController)
class MainViewController: UIViewController {

  /** @property tableViewManager
  @brief A @c StaticContentTableViewManager which is used to manage the contents of the table
  view.
  */
  @IBOutlet var tableViewManager:StaticContentTableViewManager!

  /** @property tableView
  @brief A UITableView which is used to display user info and a list of actions.
  */
  @IBOutlet weak var tableView:UITableView!

  /** @property userInfoTableViewCell
  @brief A custom UITableViewCell for displaying the user info.
  */
  @IBOutlet var userInfoTableViewCell:UITableViewCell!

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

  /** @var kSetDisplayNameTitle
  @brief The title of the "Set Display Name" error dialog.
  */
  var kSetDisplayNameTitle = "Set Display Name"

  /** @var kChangeEmailText
  @brief The title of the "Change Email" button.
  */
  var kChangeEmailText = "Change Email"

  /** @var kChangePasswordText
  @brief The title of the "Change Password" button.
  */
  var kChangePasswordText = "Change Password"

  /** @var kUnlinkTitle
  @brief The text of the "Unlink from Provider" error Dialog.
  */
  var kUnlinkTitle = "Unlink from Provider"

  /** @var kUnlinkFromGoogle
  @brief The text of the "Unlink from Google" button.
  */
  var kUnlinkFromGoogle = "Unlink from Google"

  /** @var kUnlinkFromFacebook
  @brief The text of the "Unlink from Facebook" button.
  */
  var kUnlinkFromFacebook = "Unlink from Facebook"

  /** @var kGetProvidersForEmail
  @brief The text of the "Get Provider IDs for Email" button.
  */
  var kGetProvidersForEmail = "Get Provider IDs for Email"

  /** @var kRequestVerifyEmail
  @brief The text of the "Request Verify Email Link" button.
  */
  var kRequestVerifyEmail = "Request Verify Email Link"

  /** @var kRequestPasswordReset
  @brief The text of the "Password Reset" button.
  */
  var kRequestPasswordReset = "Password Reset"

  /** @var kNoNotificationMessage
  @brief The text of the notification box if actions doesn't carry notification.
  */
  var kNoNotificationMessage = "-"

  /** @fn initWithNibName:bundle:
   @brief Overridden default initializer.
   */
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "authStateChangedForAuth:",
        name: FIRAuthStateDidChangeNotification, object: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  override func viewDidLoad() {
    // Give us a circle for the image view:
    userInfoProfileURLImageView.layer.cornerRadius =
      userInfoProfileURLImageView.frame.size.width / 2.0
    userInfoProfileURLImageView.layer.masksToBounds = true
    updateUserInfo(FIRAuth.auth()!)
    loadTableviewWithNotificationFlag(false)
  }

  /** @fn loadTableviewWithNotificationFlag:
  @brief Invoked to update the contents of tableview.
  @param hasNotification Flag tells us if action carried notificaiton.
  */
  func loadTableviewWithNotificationFlag(notificationFlag: Bool) {

  var notificationMessage = kNoNotificationMessage;
  if (notificationFlag) {
    let locale = NSLocale.currentLocale()
    let dateDescription = NSDate().descriptionWithLocale(locale)
    notificationMessage = "Notif: \(dateDescription)"
  }

  tableViewManager.contents = StaticContentTableViewContent.init(sections: [
    StaticContentTableViewSection.init(title: "Signed-In User Details", cells: [
      StaticContentTableViewCell.init(customCell: userInfoTableViewCell)!
      ])!,
    StaticContentTableViewSection.init(title: "Actions", cells: [
      StaticContentTableViewCell.init(title: kSignInButtonText,
        action: {[weak self] in self!.signIn()})!,
      StaticContentTableViewCell.init(title: kSignOutButtonText,
        action: {[weak self] in self!.signOut()})!,
      StaticContentTableViewCell.init(title: kTokenRefreshButtonText,
        action: {[weak self] in self!.forceTokenRefresh()})!,
      StaticContentTableViewCell.init(title: kSetDisplayNameTitle,
        action: {[weak self] in self!.setDisplayName()})!,
      StaticContentTableViewCell.init(title: kUnlinkFromGoogle,
        action: {self.unlinkFromProvider(FIRGoogleAuthProviderID)})!,
      StaticContentTableViewCell.init(title: kUnlinkFromFacebook,
        action: {self.unlinkFromProvider(FIRFacebookAuthProviderID)})!,
      StaticContentTableViewCell.init(title: kGetProvidersForEmail,
        action: {[weak self] in self!.getProvidersForEmail()})!,
      StaticContentTableViewCell.init(title: kRequestVerifyEmail,
        action: {[weak self] in self!.requestVerifyEmail()})!,
      StaticContentTableViewCell.init(title: kRequestPasswordReset,
        action: {[weak self] in self!.requestPasswordReset()})!,
      StaticContentTableViewCell.init(title: kChangeEmailText,
        action: {[weak self] in self!.changeEmail()})!,
      StaticContentTableViewCell.init(title: kChangePasswordText,
        action: {[weak self] in self!.changePassword()})!
      ])!,
    StaticContentTableViewSection.init(title: "Notifications", cells: [
      StaticContentTableViewCell.init(title: notificationMessage)!
      ])!
    ]);
  }

  // MARK: - Actions

  /** @fn signIn
   @brief Invoked when the sign in row is pressed.
   */
  func signIn() {
    // [START usermanagement_config]
    let firebaseAuth = FIRAuth.auth
    // [END usermanagement_config]
    let firebaseAuthUI:FIRAuthUI = FIRAuthUI.init(forApp: firebaseAuth()!.app!)!

    firebaseAuthUI.presentSignInWithViewController(self, callback: {(user, error) in
      let okAction = UIAlertAction.init(title: self.kOKButtonText, style: .Default,
          handler: {action in print(self.kOKButtonText)})
      if ((error) != nil) {
        let alertController  = UIAlertController.init(title: self.kSignInErrorAlertTitle,
            message: error!.localizedDescription, preferredStyle: .Alert)
        alertController.addAction(okAction)
        self.presentViewController(alertController, animated: true, completion: nil)
        return
      }

      // Log sign in event to Scion.
      FIRAnalytics.logEventWithName(kFIREventLogin, parameters: nil)

      let alertController = UIAlertController.init(title: self.kSignedInAlertTitle,
          message: user!.displayName, preferredStyle: .Alert)
      alertController.addAction(okAction)
      self.presentViewController(alertController, animated: true, completion: nil)
    })
  }

  /** @fn signOut
   @brief Signs the user out.
   */
  func signOut() {
    let firebaseAuth = FIRAuth.auth()
    do {
      try firebaseAuth?.signOut()
    } catch {
      print ("Could not sign out.")
    }
  }

  /** @fn forceTokenRefresh
   @brief Invoked when the token refresh row is pressed.
   */
  func forceTokenRefresh() {
    let action: FIRAuthTokenCallback = {(token, error) in
      let okAction = UIAlertAction.init(title: self.kOKButtonText, style: .Default,
        handler: {action in print(self.kOKButtonText)})
      if (error != nil) {
        let alertController  = UIAlertController.init(title: self.kTokenRefreshErrorAlertTitle,
          message: error!.localizedDescription, preferredStyle: .Alert)
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
    FIRAuth.auth()?.currentUser?.getTokenForcingRefresh(true, callback: action)
  }

  /** @fn setDisplayName
  @brief Changes the display name of the current user.
  */
  func setDisplayName() {
    showTextInputPromptWithMessage("Display Name:", completionBlock: { (userPressedOK, userInput) in
      if (userPressedOK != true) || userInput!.isEmpty {
        return
      }

      self.showSpinner({
        let changeRequest = FIRAuth.auth()?.currentUser?.profileChangeRequest()
        changeRequest?.displayName = userInput!
        changeRequest?.commitChangesWithCallback({ (error) in
          self.hideSpinner({
            self.showTypicalUIForUserUpdateResultsWithTitle(self.kSetDisplayNameTitle, error: error)
            self.updateUserInfo(FIRAuth.auth()!)
          })
        })
      })
    })
  }

  /** @fn unlinkFromProvider:
  @brief Unlinks the current user from the provider with the specified provider ID.
  @param provider The provider ID of the provider to unlink the current user's account from.
  */
  func unlinkFromProvider(provider: String) {
    FIRAuth.auth()?.currentUser?.unlinkFromProvider(provider, callback: { (user, error) in
      self.showTypicalUIForUserUpdateResultsWithTitle(self.kUnlinkTitle, error: error)
      self.updateUserInfo(FIRAuth.auth()!)
    })
  }

  /** @fn getProvidersForEmail
  @brief Prompts the user for an email address, calls @c FIRAuth.getProvidersForEmail:callback:
  and displays the result.
  */
  func getProvidersForEmail() {
    showTextInputPromptWithMessage("Email:", completionBlock: { (userPressedOK, userInput) in
      if (userPressedOK != true) || userInput!.isEmpty {
        return
      }

      self.showSpinner({
        FIRAuth.auth()!.getProvidersForEmail(userInput!, callback: { (providers, error) in
          self.hideSpinner({
            if (error != nil) {
              self.showMessagePrompt(error!.localizedDescription)
              return
            }

            self.showMessagePrompt(providers!.joinWithSeparator(", "))
          })
        })
      })
    })
  }

  /** @fn requestVerifyEmail
  @brief Requests a "verify email" email be sent.
  */
  func requestVerifyEmail() {
    showSpinner({
      FIRAuth.auth()!.currentUser!.sendEmailVerification({ (error) in
        self.hideSpinner({
          if (error != nil) {
            self.showMessagePrompt(error!.localizedDescription)
            return
          }

          self.showMessagePrompt("Sent")
        })
      })
    })
  }

  /** @fn requestPasswordReset
  @brief Requests a "password reset" email be sent.
  */
  func requestPasswordReset() {
    showTextInputPromptWithMessage("Email:", completionBlock:{ (userPressedOK, userInput) in
      if (userPressedOK != true) || userInput!.isEmpty {
        return
      }

      self.showSpinner({
        FIRAuth.auth()!.sendPasswordResetWithEmail(userInput!, callback:{ (error) in
          self.hideSpinner({
            if (error != nil) {
              self.showMessagePrompt(error!.localizedDescription)
              return
            }

            self.showMessagePrompt("Sent")
          })
        })
      })
    })
  }

  /** @fn changeEmail
  @brief Changes the email address of the current user.
  */
  func changeEmail() {
    showTextInputPromptWithMessage("Email Address:", completionBlock:{ (userPressedOK, userInput) in
      if (userPressedOK != true) || userInput!.isEmpty {
        return
      }

      self.showSpinner({
        FIRAuth.auth()!.currentUser!.changeEmail(userInput!, callback:{ (error) in
          self.hideSpinner({
            self.showTypicalUIForUserUpdateResultsWithTitle(self.kChangeEmailText, error:error)
            self.updateUserInfo(FIRAuth.auth()!)
          })
        })
      })
    })
  }

  /** @fn changePassword
  @brief Changes the password of the current user.
  */
  func changePassword() {
    showTextInputPromptWithMessage("New Password:", completionBlock:{ (userPressedOK, userInput) in
      if (userPressedOK != true) || userInput!.isEmpty {
        return
      }

      self.showSpinner({
        FIRAuth.auth()!.currentUser!.changePassword(userInput!, callback:{ (error) in
          self.hideSpinner({
            self.showTypicalUIForUserUpdateResultsWithTitle(self.kChangePasswordText, error:error)
            self.updateUserInfo(FIRAuth.auth()!)
          })
        })
      })
    })
  }

  // MARK: - Helpers

  /** @fn showTypicalUIForUserUpdateResultsWithTitle:error:
  @brief Shows a @c UIAlertView if error is non-nil with the localized description of the error.
  @param resultsTitle The title of the @c UIAlertView
  @param error The error details to display if non-nil.
  */
  func showTypicalUIForUserUpdateResultsWithTitle(resultsTitle: String, error: NSError?) {
    if (error != nil) {
      let message = "\(error!.domain) (\(error!.code))\n\(error!.localizedDescription)"
      let okAction = UIAlertAction.init(title: self.kOKButtonText, style: .Default,
        handler: {action in print(self.kOKButtonText)})
      let alertController  = UIAlertController.init(title: resultsTitle,
        message: message, preferredStyle: .Alert)
      alertController.addAction(okAction)
      self.presentViewController(alertController, animated: true, completion: nil)
      return
    }
  }

  func updateUserInfo(firebaseAuth: FIRAuth) {
    let user = firebaseAuth.currentUser
    userInfoDisplayNameLabel.text = user!.displayName
    userInfoEmailLabel.text = user!.email
    userInfoUserIDLabel.text = user!.userID

    var providerIDs = [String]()
    for userInfo in user!.providerData {
      providerIDs.append(userInfo.providerID)
    }
    userInfoProviderListLabel.text = providerIDs.joinWithSeparator(", ")

    let photoURL = user!.photoURL
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

  func authStateChangedForAuth(notification: NSNotification) {
    let auth = notification.object as! FIRAuth
    updateUserInfo(auth)
    loadTableviewWithNotificationFlag(true)
  }
}
