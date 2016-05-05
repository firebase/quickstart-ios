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
class MainViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate, GIDSignInDelegate, GIDSignInUIDelegate {

  let kSectionToken = 3
  let kSectionProviders = 2
  let kSectionUser = 1
  let kSectionSignIn = 0

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

  var handle: FIRAuthStateDidChangeListenerHandle?
  var maskView: UIView?
  var providerPickerView: UIPickerView?
  var providerToolbar: UIToolbar?
  var selectedRow: Int?
  var pickerData: Array<String>?

  func createPickerView() {
    selectedRow = 0
    maskView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: view.bounds.size.width, height: view.bounds.size.height))
    maskView!.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.5)

    view.addSubview(maskView!)
    providerToolbar = UIToolbar.init(frame: CGRect.init(x: 0, y: view.bounds.size.height - 344, width: view.bounds.size.width, height: 44))

    let done = UIBarButtonItem.init(barButtonSystemItem: .Done, target: self, action: #selector(MainViewController.dismissActionSheet(_:)))
    providerToolbar!.items = [UIBarButtonItem.init(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil), done]
    providerToolbar!.barStyle = .Black
    view.addSubview(providerToolbar!)

    providerPickerView = UIPickerView.init(frame: CGRect.init(x: 0, y: view.bounds.size.height - 300, width: 0, height: 0))
    providerPickerView!.backgroundColor = UIColor.init(red: 1, green: 1, blue: 1, alpha: 0.5)
    providerPickerView!.showsSelectionIndicator = true
    providerPickerView!.dataSource = self
    providerPickerView!.delegate = self

    view.addSubview(providerPickerView!)
  }

  func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return pickerData!.count
  }

  func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return pickerData![row]
  }

  func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    selectedRow = row
  }

  @IBAction func didTapSignIn(sender: AnyObject) {
    pickerData = ["Email", FIRFacebookAuthProviderID, FIRGoogleAuthProviderID, FIRTwitterAuthProviderID, "Guest", "CustomToken"]
    createPickerView()
  }

  @IBAction func didTapLink(sender: AnyObject) {
    var pickerData = [FIRFacebookAuthProviderID, FIRGoogleAuthProviderID, FIRTwitterAuthProviderID]
    for userInfo in (FIRAuth.auth()?.currentUser?.providerData)! {
      if let index = pickerData.indexOf(userInfo.providerID) {
        pickerData.removeAtIndex(index)
      }
    }
    self.pickerData = pickerData
    createPickerView()
  }

  func dismissActionSheet(sender: AnyObject) {
    maskView!.removeFromSuperview()
    providerPickerView!.removeFromSuperview()
    providerToolbar!.removeFromSuperview()
    let selectedProvider = pickerData![selectedRow!]
    switch selectedProvider {
    case FIRFacebookAuthProviderID:
      let loginManager = FBSDKLoginManager()
      loginManager.logInWithReadPermissions(["email"], fromViewController: self, handler: { (result, error) in
        if let error = error {
          self.showMessagePrompt(error.localizedDescription)
        } else if(result.isCancelled) {
          print("FBLogin cancelled")
        } else {
          // [START headless_facebook_auth]
          let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
          // [END headless_facebook_auth]
          self.firebaseLogin(credential)
        }
      })
    case FIRGoogleAuthProviderID:
      GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
      GIDSignIn.sharedInstance().uiDelegate = self
      GIDSignIn.sharedInstance().delegate = self
      GIDSignIn.sharedInstance().signIn()
    case FIRTwitterAuthProviderID:
      Twitter.sharedInstance().logInWithCompletion() { (session, error) in
        if let session = session {
          // [START headless_twitter_auth]
          let credential = FIRTwitterAuthProvider.credentialWithToken(session.authToken, secret: session.authTokenSecret)
          // [END headless_twitter_auth]
          self.firebaseLogin(credential)
        } else {
          self.showMessagePrompt((error?.localizedDescription)!)
        }
      }
    case "CustomToken":
      performSegueWithIdentifier("customToken", sender: nil)
    case "Guest":
      self.showSpinner({
        // [START firebase_auth_anonymous]
        FIRAuth.auth()?.signInAnonymouslyWithCompletion() { (user, error) in
          // [END firebase_auth_anonymous]
          self.hideSpinner({
            if let error = error {
              self.showMessagePrompt(error.localizedDescription)
              return
            }
          })
        }
      })
    default:
      break
    }
  }

  func firebaseLogin(credential: FIRAuthCredential) {
    showSpinner({
      if let user = FIRAuth.auth()?.currentUser {
        // [START link_credential]
        user.linkWithCredential(credential) { (user, error) in
          // [END link_credential]
          self.hideSpinner({
            if let error = error {
              self.showMessagePrompt(error.localizedDescription)
              return
            }
          })
        }
      } else {
        // [START signin_credential]
        FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
          // [END signin_credential]
          self.hideSpinner({
            if let error = error {
              self.showMessagePrompt(error.localizedDescription)
              return
            }
          })
        }
      }
    })
  }

  // [START headless_google_auth]
  func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError?) {
    if let error = error {
      self.showMessagePrompt(error.localizedDescription)
      return
    }

    let authentication = user.authentication
    let credential = FIRGoogleAuthProvider.credentialWithIDToken(authentication.idToken, accessToken: authentication.accessToken)
    // [END headless_google_auth]
    firebaseLogin(credential)
  }

  @IBAction func didSignOut(sender: AnyObject) {
    // [START signout]
    let firebaseAuth = FIRAuth.auth()
    do {
      try firebaseAuth?.signOut()
    } catch let signOutError as NSError {
      print ("Error signing out: %@", signOutError)
    }
    // [END signout]
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    handle = FIRAuth.auth()?.addAuthStateDidChangeListener() { (auth, user) in
      if let user = user {
        self.navigationItem.title = user.displayName
      } else {
        self.navigationItem.title = "Sign In"
      }
      self.tableView.reloadData()
    }
  }

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    FIRAuth.auth()?.removeAuthStateDidChangeListener(handle!)
  }

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
      return (FIRAuth.auth()?.currentUser?.providerData.count)!
    default:
      return 0
    }
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell: UITableViewCell?
    switch indexPath.section {
    case kSectionSignIn:
      if FIRAuth.auth()?.currentUser != nil {
        cell = tableView.dequeueReusableCellWithIdentifier("SignOut")
      } else {
        cell = tableView.dequeueReusableCellWithIdentifier("SignIn")
      }
    case kSectionUser:
      cell = tableView.dequeueReusableCellWithIdentifier("Profile")
      let user = FIRAuth.auth()?.currentUser
      let emailLabel = cell?.viewWithTag(1) as! UILabel
      let userIDLabel = cell?.viewWithTag(2) as! UILabel
      let profileImageView = cell?.viewWithTag(3) as! UIImageView
      emailLabel.text = user?.email
      userIDLabel.text = user?.uid

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
              profileImageView.image = image
            }
          })
        })
      } else {
        profileImageView.image = UIImage.init(named: "ic_account_circle")
      }
    case kSectionProviders:
      cell = tableView.dequeueReusableCellWithIdentifier("Provider")
      let userInfo = FIRAuth.auth()?.currentUser?.providerData[indexPath.row]
      cell?.textLabel?.text = userInfo?.providerID
      cell?.detailTextLabel?.text = userInfo?.uid
    case kSectionToken:
      cell = tableView.dequeueReusableCellWithIdentifier("Token")
    default:
      cell = nil
    }
    return cell!
  }

  override func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
    return "Unlink"
  }

  // Swipe to delete
  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
      let providerID = FIRAuth.auth()?.currentUser?.providerData[indexPath.row].providerID
      showSpinner({
        // [START unlink_provider]
        FIRAuth.auth()?.currentUser?.unlinkFromProvider(providerID!) { (user, error) in
          // [END unlink_provider]
          self.hideSpinner({
            if let error = error {
              self.showMessagePrompt(error.localizedDescription)
              return
            }
            tableView.reloadData()
          })
        }
      })
    }
  }

  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    if indexPath.section == kSectionUser {
      return 200
    }
    return 44
  }

  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 4
  }

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
    FIRAuth.auth()?.currentUser?.getTokenForcingRefresh(true, completion: action)
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
        changeRequest?.commitChangesWithCompletion() { (error) in
          // [END profile_change]
          self.hideSpinner({
            self.showTypicalUIForUserUpdateResultsWithTitle(self.kSetDisplayNameTitle, error: error)
            self.navigationItem.title = FIRAuth.auth()?.currentUser?.displayName
          })
        }
      })
    }
  }

  /** @fn requestVerifyEmail
  @brief Requests a "verify email" email be sent.
  */
  @IBAction func didRequestVerifyEmail(sender: AnyObject) {
    showSpinner({
      // [START send_verification_email]
      FIRAuth.auth()!.currentUser!.sendEmailVerificationWithCompletion({ (error) in
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
    tableView.reloadData()
  }

}
