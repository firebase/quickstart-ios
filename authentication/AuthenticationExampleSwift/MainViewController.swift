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

// [START usermanagement_view_import]
import Firebase
// [END usermanagement_view_import]
import GoogleSignIn
import FBSDKCoreKit
import FBSDKLoginKit
import TwitterKit

@objc(MainViewController)
// [START signin_controller]
class MainViewController: UITableViewController, GIDSignInUIDelegate {
// [END signin_controller]

  let kSectionToken = 3
  let kSectionProviders = 2
  let kSectionUser = 1
  let kSectionSignIn = 0

  enum AuthProvider {
    case authEmail
    case authAnonymous
    case authFacebook
    case authGoogle
    case authTwitter
    case authCustom
  }

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

  /** @var handle
   @brief The handler for the auth state listener, to allow cancelling later.
   */
  var handle: FIRAuthStateDidChangeListenerHandle?

  func showAuthPicker(_ providers: [AuthProvider]) {
    let picker = UIAlertController(title: "Select Provider",
                                   message: nil,
                                   preferredStyle: .alert)
    for provider in providers {
      var action: UIAlertAction
      switch provider {
      case .authEmail:
        action = UIAlertAction(title: "Email", style: .default, handler: { (UIAlertAction) in
          self.performSegue(withIdentifier: "email", sender:nil)
        })
      case .authCustom:
        action = UIAlertAction(title: "Custom", style: .default, handler: { (UIAlertAction) in
          self.performSegue(withIdentifier: "customToken", sender: nil)
        })
      case .authAnonymous:
        action = UIAlertAction(title: "Anonymous", style: .default, handler: { (UIAlertAction) in
          self.showSpinner({
            // [START firebase_auth_anonymous]
            FIRAuth.auth()?.signInAnonymously() { (user, error) in
              // [START_EXCLUDE]
              self.hideSpinner({
                if let error = error {
                  self.showMessagePrompt(error.localizedDescription)
                  return
                }
              })
              // [END_EXCLUDE]
            }
            // [END firebase_auth_anonymous]
          })

        })
      case .authFacebook:
        action = UIAlertAction(title: "Facebook", style: .default, handler: { (UIAlertAction) in
          let loginManager = FBSDKLoginManager()
          loginManager.logIn(withReadPermissions: ["email"], from: self, handler: { (result, error) in
            if let error = error {
              self.showMessagePrompt(error.localizedDescription)
            } else if result!.isCancelled {
              print("FBLogin cancelled")
            } else {
              // [START headless_facebook_auth]
              let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
              // [END headless_facebook_auth]
              self.firebaseLogin(credential)
            }
          })
        })
      case .authGoogle:
        action = UIAlertAction(title: "Google", style: .default, handler: { (UIAlertAction) in
          // [START setup_gid_uidelegate]
          GIDSignIn.sharedInstance().uiDelegate = self
          GIDSignIn.sharedInstance().signIn()
          // [END setup_gid_uidelegate]
        })
      case .authTwitter:
        action = UIAlertAction(title: "Twitter", style: .default, handler: { (UIAlertAction) in
          Twitter.sharedInstance().logIn() { (session, error) in
            if let session = session {
              // [START headless_twitter_auth]
              let credential = FIRTwitterAuthProvider.credential(withToken: session.authToken, secret: session.authTokenSecret)
              // [END headless_twitter_auth]
              self.firebaseLogin(credential)
            } else {
              self.showMessagePrompt((error?.localizedDescription)!)
            }
          }
        })
      }
      picker.addAction(action)
    }

    picker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    present(picker, animated: true, completion: nil)

  }

  @IBAction func didTapSignIn(_ sender: AnyObject) {
    showAuthPicker([
      AuthProvider.authEmail,
      AuthProvider.authAnonymous,
      AuthProvider.authGoogle,
      AuthProvider.authFacebook,
      AuthProvider.authTwitter,
      AuthProvider.authCustom
    ])
  }

  @IBAction func didTapLink(_ sender: AnyObject) {
    var providers = Set([
      AuthProvider.authGoogle,
      AuthProvider.authFacebook,
      AuthProvider.authTwitter
    ])
    // Remove any existing providers. Note that this is not a complete list of
    // providers, so always check the documentation for a complete reference:
    // https://firebase.google.com/docs/auth
    let user = FIRAuth.auth()?.currentUser
    for info in (user?.providerData)! {
      if info.providerID == FIRTwitterAuthProviderID {
        providers.remove(AuthProvider.authTwitter)
      } else if info.providerID == FIRFacebookAuthProviderID {
        providers.remove(AuthProvider.authFacebook)
      } else if info.providerID == FIRGoogleAuthProviderID {
        providers.remove(AuthProvider.authGoogle)
      }
    }
    showAuthPicker(Array(providers))
  }

  func setTitleDisplay(_ user: FIRUser?) {
    if let name = user?.displayName {
      self.navigationItem.title = "Welcome \(name)"
    } else {
      self.navigationItem.title = "Authentication Example"
    }
  }

  func firebaseLogin(_ credential: FIRAuthCredential) {
    showSpinner({
      if let user = FIRAuth.auth()?.currentUser {
        // [START link_credential]
        user.link(with: credential) { (user, error) in
          // [START_EXCLUDE]
          self.hideSpinner({
            if let error = error {
              self.showMessagePrompt(error.localizedDescription)
              return
            }
            self.tableView.reloadData()
          })
          // [END_EXCLUDE]
        }
        // [END link_credential]
      } else {
        // [START signin_credential]
        FIRAuth.auth()?.signIn(with: credential) { (user, error) in
          // [START_EXCLUDE]
          self.hideSpinner({
            // [END_EXCLUDE]
            if let error = error {
              // [START_EXCLUDE]
              self.showMessagePrompt(error.localizedDescription)
              // [END_EXCLUDE]
              return
            }
            // [END signin_credential]
            // Merge prevUser and currentUser accounts and data
            // ...
          })
        }
      }
    })
  }

  @IBAction func didTapSignOut(_ sender: AnyObject) {
    // [START signout]
    let firebaseAuth = FIRAuth.auth()
    do {
      try firebaseAuth?.signOut()
    } catch let signOutError as NSError {
      print ("Error signing out: %@", signOutError)
    }
    // [END signout]
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    // [START auth_listener]
    handle = FIRAuth.auth()?.addStateDidChangeListener() { (auth, user) in
      // [START_EXCLUDE]
      self.setTitleDisplay(user)
      self.tableView.reloadData()
      // [END_EXCLUDE]
    }
    // [END auth_listener]
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    // [START remove_auth_listener]
    FIRAuth.auth()?.removeStateDidChangeListener(handle!)
    // [END remove_auth_listener]
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch section {
    case kSectionSignIn:
      return 1
    case kSectionUser, kSectionToken:
      if FIRAuth.auth()?.currentUser != nil {
        return 1
      } else {
        return 0
      }
    case kSectionProviders:
      if let user = FIRAuth.auth()?.currentUser {
        return user.providerData.count
      }
      return 0
    default:
      return 0
    }
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell: UITableViewCell?
    switch (indexPath as NSIndexPath).section {
    case kSectionSignIn:
      // [START current_user]
      if FIRAuth.auth()?.currentUser != nil {
        // User is signed in.
        // [START_EXCLUDE]
        cell = tableView.dequeueReusableCell(withIdentifier: "SignOut")
        // [END_EXCLUDE]
      } else {
        // No user is signed in.
        // [START_EXCLUDE]
        cell = tableView.dequeueReusableCell(withIdentifier: "SignIn")
        // [END_EXCLUDE]
      }
      // [END current_user]
    case kSectionUser:
      cell = tableView.dequeueReusableCell(withIdentifier: "Profile")
      // [START get_user_profile]
      let user = FIRAuth.auth()?.currentUser
      // [END get_user_profile]
      // [START user_profile]
      if let user = user {
        // The user's ID, unique to the Firebase project.
        // Do NOT use this value to authenticate with your backend server,
        // if you have one. Use getTokenWithCompletion:completion: instead.
        let uid = user.uid
        let email = user.email
        let photoURL = user.photoURL
        // [START_EXCLUDE]
        let emailLabel = cell?.viewWithTag(1) as? UILabel
        let userIDLabel = cell?.viewWithTag(2) as? UILabel
        let profileImageView = cell?.viewWithTag(3) as? UIImageView
        emailLabel?.text = email
        userIDLabel?.text = uid

        struct last {
            static var photoURL: URL? = nil
        }
        last.photoURL = photoURL;  // to prevent earlier image overwrites later one.
        if let photoURL = photoURL {
          DispatchQueue.global(qos: .default).async {
            let data = try? Data.init(contentsOf: photoURL)
            if let data = data {
              let image = UIImage.init(data: data)
              DispatchQueue.main.async(execute: {
                if photoURL == last.photoURL {
                  profileImageView?.image = image
                }
              })
            }
          }
        } else {
          profileImageView?.image = UIImage.init(named: "ic_account_circle")
        }
        // [END_EXCLUDE]
      }
      // [END user_profile]
    case kSectionProviders:
      cell = tableView.dequeueReusableCell(withIdentifier: "Provider")
      // [START provider_data]
      let userInfo = FIRAuth.auth()?.currentUser?.providerData[(indexPath as NSIndexPath).row]
      cell?.textLabel?.text = userInfo?.providerID
      // Provider-specific UID
      cell?.detailTextLabel?.text = userInfo?.uid
      // [END provider_data]
    case kSectionToken:
      cell = tableView.dequeueReusableCell(withIdentifier: "Token")
      let requestEmailButton = cell?.viewWithTag(4) as? UIButton
      requestEmailButton?.isEnabled = (FIRAuth.auth()?.currentUser?.email != nil) ? true : false

    default:
      fatalError("Unknown section in UITableView")
    }
    return cell!
  }

  override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
    return "Unlink"
  }

  override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
    if (indexPath as NSIndexPath).section == kSectionProviders {
      return .delete
    }
    return .none
  }

  // Swipe to delete
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let providerID = FIRAuth.auth()?.currentUser?.providerData[(indexPath as NSIndexPath).row].providerID
      showSpinner({
        // [START unlink_provider]
        FIRAuth.auth()?.currentUser?.unlink(fromProvider: providerID!) { (user, error) in
          // [START_EXCLUDE]
          self.hideSpinner({
            if let error = error {
              self.showMessagePrompt(error.localizedDescription)
              return
            }
            tableView.reloadData()
          })
          // [END_EXCLUDE]
        }
        // [END unlink_provider]
      })
    }
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if (indexPath as NSIndexPath).section == kSectionUser {
      return 200
    }
    return 44
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 4
  }

  @IBAction func didTokenRefresh(_ sender: AnyObject) {
    let action: FIRAuthTokenCallback = {(token, error) in
      let okAction = UIAlertAction.init(title: self.kOKButtonText, style: .default) {
        action in print(self.kOKButtonText)
      }
      if let error = error {
        let alertController  = UIAlertController.init(title: self.kTokenRefreshErrorAlertTitle,
          message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
        return
      }

      // Log token refresh event to Scion.
      FIRAnalytics.logEvent(withName: "tokenrefresh", parameters: nil)

      let alertController = UIAlertController.init(title: self.kTokenRefreshedAlertTitle,
          message: token, preferredStyle: .alert)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    // [START token_refresh]
    FIRAuth.auth()?.currentUser?.getTokenForcingRefresh(true, completion: action)
    // [END token_refresh]
  }

  /** @fn setDisplayName
  @brief Changes the display name of the current user.
  */
  @IBAction func didSetDisplayName(_ sender: AnyObject) {
    showTextInputPrompt(withMessage: "Display Name:") { (userPressedOK, userInput) in
      if let userInput = userInput {
        self.showSpinner({
          // [START profile_change]
          let changeRequest = FIRAuth.auth()?.currentUser?.profileChangeRequest()
          changeRequest?.displayName = userInput
          changeRequest?.commitChanges() { (error) in
            // [START_EXCLUDE]
            self.hideSpinner({
              self.showTypicalUIForUserUpdateResults(withTitle: self.kSetDisplayNameTitle, error: error as NSError?)
              self.setTitleDisplay(FIRAuth.auth()?.currentUser)
            })
            // [END_EXCLUDE]
          }
          // [END profile_change]
        })
      } else {
        self.showMessagePrompt("displayname can't be empty")
      }
    }
  }

  /** @fn requestVerifyEmail
  @brief Requests a "verify email" email be sent.
  */
  @IBAction func didRequestVerifyEmail(_ sender: AnyObject) {
    showSpinner({
      // [START send_verification_email]
      FIRAuth.auth()?.currentUser?.sendEmailVerification(completion: { (error) in
        // [START_EXCLUDE]
        self.hideSpinner({
          if let error = error {
            self.showMessagePrompt(error.localizedDescription)
            return
          }
          self.showMessagePrompt("Sent")
        })
        // [END_EXCLUDE]
      })
      // [END send_verification_email]
    })
  }

  /** @fn changeEmail
  @brief Changes the email address of the current user.
  */
  @IBAction func didChangeEmail(_ sender: AnyObject) {
    showTextInputPrompt(withMessage: "Email Address:") { (userPressedOK, userInput) in
      if let userInput = userInput {
        self.showSpinner({
          // [START change_email]
          FIRAuth.auth()?.currentUser?.updateEmail(userInput) { (error) in
            // [START_EXCLUDE]
            self.hideSpinner({
              self.showTypicalUIForUserUpdateResults(withTitle: self.kChangeEmailText, error: error)
            })
            // [END_EXCLUDE]
          }
          // [END change_email]
        })
      } else {
        self.showMessagePrompt("email can't be empty")
      }
    }
  }

  /** @fn changePassword
  @brief Changes the password of the current user.
  */
  @IBAction func didChangePassword(_ sender: AnyObject) {
    showTextInputPrompt(withMessage: "New Password:") { (userPressedOK, userInput) in
      if let userInput = userInput {
        self.showSpinner({
          // [START change_password]
          FIRAuth.auth()?.currentUser?.updatePassword(userInput) { (error) in
            // [START_EXCLUDE]
            self.hideSpinner({
              self.showTypicalUIForUserUpdateResults(withTitle: self.kChangePasswordText, error: error)
            })
            // [END_EXCLUDE]
          }
          // [END change_password]
        })
      } else {
        self.showMessagePrompt("password can't be empty")
      }
    }
  }

  // MARK: - Helpers

  /** @fn showTypicalUIForUserUpdateResultsWithTitle:error:
  @brief Shows a @c UIAlertView if error is non-nil with the localized description of the error.
  @param resultsTitle The title of the @c UIAlertView
  @param error The error details to display if non-nil.
  */
  func showTypicalUIForUserUpdateResults(withTitle resultsTitle: String, error: Error?) {
    if let error = error {
      let message = "\(error.localizedDescription)"
      let okAction = UIAlertAction.init(title: self.kOKButtonText, style: .default) {
        action in print(self.kOKButtonText)
      }
      let alertController  = UIAlertController.init(title: resultsTitle,
        message: message, preferredStyle: .alert)
      alertController.addAction(okAction)
      self.present(alertController, animated: true, completion: nil)
      return
    }
    tableView.reloadData()
  }
}
