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
import GameKit

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
    case authPhone
    case authCustom
    case authPasswordless
    case authGameCenter
    case authMicrosoft
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

  /** @var kUpdatePhoneNumberText
      @brief The title of the "Update Phone Number" button.
   */
  let kUpdatePhoneNumberText = "Update Phone Number"

  /** @var handle
      @brief The handler for the auth state listener, to allow cancelling later.
   */
  var handle: AuthStateDidChangeListenerHandle?

  /** @var microsoftProvider
      @brief The OAuth provider instance for Microsoft.
   */
  var microsoftProvider : OAuthProvider?

  func showAuthPicker(_ providers: [AuthProvider]) {
    let picker = UIAlertController(title: "Select Provider",
                                   message: nil,
                                   preferredStyle: .alert)
    for provider in providers {
      var action: UIAlertAction
      switch provider {
      case .authEmail:
        action = UIAlertAction(title: "Email", style: .default) { (UIAlertAction) in
          self.performSegue(withIdentifier: "email", sender:nil)
        }
      case .authPasswordless:
        action = UIAlertAction(title: "Passwordless", style: .default) { (UIAlertAction) in
          self.performSegue(withIdentifier: "passwordless", sender:nil)
        }
      case .authCustom:
        action = UIAlertAction(title: "Custom", style: .default) { (UIAlertAction) in
          self.performSegue(withIdentifier: "customToken", sender: nil)
        }
      case .authAnonymous:
        action = UIAlertAction(title: "Anonymous", style: .default) { (UIAlertAction) in
          self.showSpinner {
            // [START firebase_auth_anonymous]
            Auth.auth().signInAnonymously() { (authResult, error) in
              // [START_EXCLUDE]
              self.hideSpinner {
                if let error = error {
                  self.showMessagePrompt(error.localizedDescription)
                  return
                }
              }
              // [END_EXCLUDE]
            }
            // [END firebase_auth_anonymous]
          }
        }
      case .authFacebook:
        action = UIAlertAction(title: "Facebook", style: .default) { (UIAlertAction) in
          let loginManager = FBSDKLoginManager()
          loginManager.logIn(withReadPermissions: ["email"], from: self, handler: { (result, error) in
            if let error = error {
              self.showMessagePrompt(error.localizedDescription)
            } else if result!.isCancelled {
              print("FBLogin cancelled")
            } else {
              // [START headless_facebook_auth]
              let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
              // [END headless_facebook_auth]
              self.firebaseLogin(credential)
            }
          })
        }
      case .authGoogle:
        action = UIAlertAction(title: "Google", style: .default) { (UIAlertAction) in
          // [START setup_gid_uidelegate]
          GIDSignIn.sharedInstance().uiDelegate = self
          GIDSignIn.sharedInstance().signIn()
          // [END setup_gid_uidelegate]
        }
      case .authTwitter:
        action = UIAlertAction(title: "Twitter", style: .default) { (UIAlertAction) in
          Twitter.sharedInstance().logIn() { (session, error) in
            if let session = session {
              // [START headless_twitter_auth]
              let credential = TwitterAuthProvider.credential(withToken: session.authToken, secret: session.authTokenSecret)
              // [END headless_twitter_auth]
              self.firebaseLogin(credential)
            } else {
              self.showMessagePrompt((error?.localizedDescription)!)
            }
          }
        }
      case .authPhone:
        action = UIAlertAction(title: "Phone", style: .default) { (UIAlertAction) in
          self.showTextInputPrompt(withMessage: "Phone Number:") { (userPressedOK, userInput) in
            if let phoneNumber = userInput {
              self.showSpinner {
                // [START phone_auth]
                PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { (verificationID, error) in
                 // [START_EXCLUDE silent]
                 self.hideSpinner {
                  // [END_EXCLUDE]
                  if let error = error {
                    self.showMessagePrompt(error.localizedDescription)
                    return
                  }
                  // Sign in using the verificationID and the code sent to the user
                  // [START_EXCLUDE]
                  guard let verificationID = verificationID else { return }
                  self.showTextInputPrompt(withMessage: "Verification Code:") { (userPressedOK, verificationCode) in
                    if let verificationCode = verificationCode {
                      // [START get_phone_cred]
                      let credential = PhoneAuthProvider.provider().credential(
                          withVerificationID: verificationID,
                          verificationCode: verificationCode)
                      // [END get_phone_cred]
                      self.firebaseLogin(credential)
                    } else {
                      self.showMessagePrompt("verification code can't be empty")
                    }
                  }
                 }
                  // [END_EXCLUDE]
                }
                // [END phone_auth]
              }
            } else {
              self.showMessagePrompt("phone number can't be empty")
            }
          }
        }
      case .authGameCenter:
        action = UIAlertAction(title: "Game Center", style: .default) { (UIAlertAction) in
          // [START firebase_auth_gamecenter]
          GameCenterAuthProvider.getCredential() { (credential, error) in
            self.showSpinner {
              if let error = error {
                self.hideSpinner {
                  self.showMessagePrompt(error.localizedDescription)
                  return
                }
              }
              if let credential = credential {
                Auth.auth().signInAndRetrieveData(with: credential) { (result, error) in
                  self.hideSpinner {
                    if let error = error {
                      self.showMessagePrompt(error.localizedDescription)
                      return
                    }
                  }
                }
              }
            }
          }
          // [END firebase_auth_gamecenter]
        }
      case .authMicrosoft:
        action = UIAlertAction(title: "Microsoft", style: .default) { (UIAlertAction) in
          // [START firebase_auth_microsoft]
          self.microsoftProvider?.getCredentialWith(_: nil){ (credential, error) in
            self.showSpinner {
              if let error = error {
                self.hideSpinner {
                  self.showMessagePrompt(error.localizedDescription)
                  return
                }
              }
              if let credential = credential {
                Auth.auth().signInAndRetrieveData(with: credential) { (result, error) in
                  self.hideSpinner {
                    if let error = error {
                      self.showMessagePrompt(error.localizedDescription)
                      return
                    }
                  }
                }
              }
            }
          }
          // [END firebase_auth_microsoft]
        }
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
      AuthProvider.authPhone,
      AuthProvider.authCustom,
      AuthProvider.authPasswordless,
      AuthProvider.authGameCenter,
      AuthProvider.authMicrosoft,
    ])
  }

  @IBAction func didTapLink(_ sender: AnyObject) {
    var providers = Set([
      AuthProvider.authGoogle,
      AuthProvider.authFacebook,
      AuthProvider.authTwitter,
      AuthProvider.authPhone
    ])
    // Remove any existing providers. Note that this is not a complete list of
    // providers, so always check the documentation for a complete reference:
    // https://firebase.google.com/docs/auth
    let user = Auth.auth().currentUser
    for info in (user?.providerData)! {
      switch info.providerID {
      case TwitterAuthProviderID:
        providers.remove(AuthProvider.authTwitter)
      case FacebookAuthProviderID:
        providers.remove(AuthProvider.authFacebook)
      case GoogleAuthProviderID:
        providers.remove(AuthProvider.authGoogle)
      case PhoneAuthProviderID:
        providers.remove(AuthProvider.authPhone)
      default:
        break
      }
    }
    showAuthPicker(Array(providers))
  }

  func setTitleDisplay(_ user: User?) {
    if let name = user?.displayName {
      self.navigationItem.title = "Welcome \(name)"
    } else {
      self.navigationItem.title = "Authentication Example"
    }
  }

  func firebaseLogin(_ credential: AuthCredential) {
    showSpinner {
      if let user = Auth.auth().currentUser {
        // [START link_credential]
        user.linkAndRetrieveData(with: credential) { (authResult, error) in
          // [START_EXCLUDE]
          self.hideSpinner {
            if let error = error {
              self.showMessagePrompt(error.localizedDescription)
              return
            }
            self.tableView.reloadData()
          }
          // [END_EXCLUDE]
        }
        // [END link_credential]
      } else {
        // [START signin_credential]
        Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
          // [START_EXCLUDE silent]
          self.hideSpinner {
          // [END_EXCLUDE]
          if let error = error {
            // [START_EXCLUDE]
            self.showMessagePrompt(error.localizedDescription)
            // [END_EXCLUDE]
            return
          }
          // User is signed in
          // [START_EXCLUDE]
          // Merge prevUser and currentUser accounts and data
          // ...
          // [END_EXCLUDE]
          // [START_EXCLUDE silent]
          }
          // [END_EXCLUDE]
        }
        // [END signin_credential]
      }
    }
  }

  @IBAction func didTapSignOut(_ sender: AnyObject) {
    // [START signout]
    let firebaseAuth = Auth.auth()
    do {
      try firebaseAuth.signOut()
    } catch let signOutError as NSError {
      print ("Error signing out: %@", signOutError)
    }
    // [END signout]
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    // [START auth_listener]
    handle = Auth.auth().addStateDidChangeListener { (auth, user) in
      // [START_EXCLUDE]
      self.setTitleDisplay(user)
      self.tableView.reloadData()
      // [END_EXCLUDE]
    }
    // [END auth_listener]
    self.microsoftProvider = OAuthProvider.init(providerID:"microsoft.com");
    // Authenticate Game Center Local Player
    // Uncomment to sign in with Game Center
    // self.authenticateGameCenterLocalPlayer()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    // [START remove_auth_listener]
    Auth.auth().removeStateDidChangeListener(handle!)
    // [END remove_auth_listener]
  }

  func authenticateGameCenterLocalPlayer() {
    let localPlayer = GKLocalPlayer.local
    localPlayer.authenticateHandler = { (gcAuthViewController, error) in
      if let gcAuthViewController = gcAuthViewController {
        // Pause any activities that require user interaction, then present the
        // gcAuthViewController to the player.
        self.present(gcAuthViewController, animated: true, completion: nil)
      } else if localPlayer.isAuthenticated {
        // Local player is logged in to Game Center.
      } else {
        // Error
        if let error = error {
          self.showMessagePrompt(error.localizedDescription)
          return
        }
      }
    }
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch section {
    case kSectionSignIn:
      return 1
    case kSectionUser, kSectionToken:
      if Auth.auth().currentUser != nil {
        return 1
      } else {
        return 0
      }
    case kSectionProviders:
      if let user = Auth.auth().currentUser {
        return user.providerData.count
      }
      return 0
    default:
      return 0
    }
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell: UITableViewCell?
    switch indexPath.section {
    case kSectionSignIn:
      // [START current_user]
      if Auth.auth().currentUser != nil {
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
      let user = Auth.auth().currentUser
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
            let data = try? Data(contentsOf: photoURL)
            if let data = data {
              let image = UIImage(data: data)
              DispatchQueue.main.async(execute: {
                if photoURL == last.photoURL {
                  profileImageView?.image = image
                }
              })
            }
          }
        } else {
          profileImageView?.image = UIImage(named: "ic_account_circle")
        }
        // [END_EXCLUDE]
      }
      // [END user_profile]
    case kSectionProviders:
      cell = tableView.dequeueReusableCell(withIdentifier: "Provider")
      // [START provider_data]
      let userInfo = Auth.auth().currentUser?.providerData[indexPath.row]
      cell?.textLabel?.text = userInfo?.providerID
      // Provider-specific UID
      cell?.detailTextLabel?.text = userInfo?.uid
      // [END provider_data]
    case kSectionToken:
      cell = tableView.dequeueReusableCell(withIdentifier: "Token")
      let requestEmailButton = cell?.viewWithTag(4) as? UIButton
      requestEmailButton?.isEnabled = (Auth.auth().currentUser?.email != nil) ? true : false

    default:
      fatalError("Unknown section in UITableView")
    }
    return cell!
  }

  override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
    return "Unlink"
  }

  override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    if indexPath.section == kSectionProviders {
      return .delete
    }
    return .none
  }

  // Swipe to delete
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let providerID = Auth.auth().currentUser?.providerData[indexPath.row].providerID
      showSpinner({
        // [START unlink_provider]
        Auth.auth().currentUser?.unlink(fromProvider: providerID!) { (user, error) in
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
    if indexPath.section == kSectionUser {
      return 200
    }
    return 44
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 4
  }

  @IBAction func didTokenRefresh(_ sender: AnyObject) {
    let action: AuthTokenCallback = {(token, error) in
      let okAction = UIAlertAction(title: self.kOKButtonText, style: .default) {
        action in print(self.kOKButtonText)
      }
      if let error = error {
        let alertController  = UIAlertController(title: self.kTokenRefreshErrorAlertTitle,
          message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
        return
      }

      // Log token refresh event to Scion.
      Analytics.logEvent("tokenrefresh", parameters: nil)

      let alertController = UIAlertController(title: self.kTokenRefreshedAlertTitle,
          message: token, preferredStyle: .alert)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    // [START token_refresh]
    Auth.auth().currentUser?.getIDTokenForcingRefresh(true, completion: action)
    // [END token_refresh]
  }

  /** @fn setDisplayName
  @brief Changes the display name of the current user.
  */
  @IBAction func didSetDisplayName(_ sender: AnyObject) {
    showTextInputPrompt(withMessage: "Display Name:") { (userPressedOK, userInput) in
      if let displayName = userInput {
        self.showSpinner {
          // [START profile_change]
          let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
          changeRequest?.displayName = displayName
          changeRequest?.commitChanges { (error) in
            // [START_EXCLUDE]
            self.hideSpinner {
              self.showTypicalUIForUserUpdateResults(withTitle: self.kSetDisplayNameTitle, error: error as NSError?)
              self.setTitleDisplay(Auth.auth().currentUser)
            }
            // [END_EXCLUDE]
          }
          // [END profile_change]
        }
      } else {
        self.showMessagePrompt("displayname can't be empty")
      }
    }
  }

  /** @fn requestVerifyEmail
  @brief Requests a "verify email" email be sent.
  */
  @IBAction func didRequestVerifyEmail(_ sender: AnyObject) {
    showSpinner {
      // [START send_verification_email]
      Auth.auth().currentUser?.sendEmailVerification { (error) in
        // [START_EXCLUDE]
        self.hideSpinner {
          if let error = error {
            self.showMessagePrompt(error.localizedDescription)
            return
          }
          self.showMessagePrompt("Sent")
        }
        // [END_EXCLUDE]
      }
      // [END send_verification_email]
    }
  }

  /** @fn changeEmail
  @brief Changes the email address of the current user.
  */
  @IBAction func didChangeEmail(_ sender: AnyObject) {
    showTextInputPrompt(withMessage: "Email Address:") { (userPressedOK, userInput) in
      if let email = userInput {
        self.showSpinner {
          // [START change_email]
          Auth.auth().currentUser?.updateEmail(to: email) { (error) in
            // [START_EXCLUDE]
            self.hideSpinner {
              self.showTypicalUIForUserUpdateResults(withTitle: self.kChangeEmailText, error: error)
            }
            // [END_EXCLUDE]
          }
          // [END change_email]
        }
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
      if let password = userInput {
        self.showSpinner {
          // [START change_password]
          Auth.auth().currentUser?.updatePassword(to: password) { (error) in
            // [START_EXCLUDE]
            self.hideSpinner {
              self.showTypicalUIForUserUpdateResults(withTitle: self.kChangePasswordText, error: error)
            }
            // [END_EXCLUDE]
          }
          // [END change_password]
        }
      } else {
        self.showMessagePrompt("password can't be empty")
      }
    }
  }

  /** @fn updatePhoneNumber
   @brief Updates the phone number of the current user.
   */
  @IBAction func didUpdatePhoneNumber(_ sender: AnyObject) {
    showTextInputPrompt(withMessage: "New Phone Number:") { (userPressedOK, userInput) in
      if let phoneNumber = userInput {
        self.showSpinner {
          // [START update_phone]
          PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { (verificationID, error) in
            // [START_EXCLUDE]
            self.hideSpinner {
              if let error = error {
                self.showMessagePrompt(error.localizedDescription)
                return
              }
              guard let verificationID = verificationID else { return }
              self.showTextInputPrompt(withMessage: "Verification Code:") { (userPressedOK, userInput) in
                if let verificationCode = userInput {
                  self.showSpinner {
                    // [END_EXCLUDE]
                    let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
                    Auth.auth().currentUser?.updatePhoneNumber(credential) { (error) in
                      // [END update_phone]
                      self.hideSpinner {
                        self.showTypicalUIForUserUpdateResults(withTitle: self.kUpdatePhoneNumberText, error: error)
                      }
                    }
                  }
                } else {
                  self.showMessagePrompt("verification code can't be empty")
                }
              }
            }
          }
        }
      } else {
        self.showMessagePrompt("phone number can't be empty")
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
      let okAction = UIAlertAction(title: self.kOKButtonText, style: .default) {
        action in print(self.kOKButtonText)
      }
      let alertController  = UIAlertController(title: resultsTitle,
        message: message, preferredStyle: .alert)
      alertController.addAction(okAction)
      self.present(alertController, animated: true, completion: nil)
      return
    }
    tableView.reloadData()
  }
}

