// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import Firebase

// For Account Linking with Sign in with Google.
import GoogleSignIn

// For Account Linking with Sign in with Facebook.
import FBSDKLoginKit

// For Account Linking with Sign in with Apple.
import AuthenticationServices
import CryptoKit

class AccountLinkingViewController: UIViewController, DataSourceProviderDelegate {
  var dataSourceProvider: DataSourceProvider<AuthProvider>!

  var tableView: UITableView { view as! UITableView }

  override func loadView() {
    view = UITableView(frame: .zero, style: .insetGrouped)
  }

  let user: User

  /// Designated initializer requires a valid, non-nil Firebase user.
  /// - Parameter user: An instance of a Firebase `User`.
  init(for user: User) {
    self.user = user
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureNavigationBar()
    configureDataSourceProvider()
    registerForLoginNotifications()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setTitleColor(.systemOrange)
  }

  // MARK: - DataSourceProviderDelegate

  func didSelectRowAt(_ indexPath: IndexPath, on tableView: UITableView) {
    let item = dataSourceProvider.item(at: indexPath)

    let providerName = item.title!

    guard let provider = AuthProvider(rawValue: providerName) else {
      // The row tapped has no affiliated action.
      return
    }

    // If the item's affiliated provider is currently linked with the user,
    // unlink the provider from the user's account.
    if item.isChecked {
      unlinkFromProvider(provider.id)
      return
    }

    switch provider {
    case .google:
      performGoogleAccountLink()

    case .apple:
      performAppleAccountLink()

    case .facebook:
      performFacebookAccountLink()

    case .twitter, .microsoft, .gitHub, .yahoo:
      performOAuthAccountLink(for: provider)

    case .emailPassword:
      performEmailPasswordAccountLink()

    case .passwordless:
      performPasswordlessAccountLink()

    case .phoneNumber:
      performPhoneNumberAccountLink()

    default:
      break
    }
  }

  // MARK: Firebase 🔥

  /// Wrapper method that uses Firebase's `link(with:)` API to link a user to another auth provider.
  /// Used when linking a user to each of the following auth providers.
  /// This method will update the UI upon the linking's completion.
  /// - Parameter authCredential: The credential used to link the user with the auth provider.
  private func linkAccount(authCredential: AuthCredential) {
    user.link(with: authCredential) { result, error in
      guard error == nil else { return self.displayError(error) }
      self.updateUI()
    }
  }

  /// Wrapper method that uses Firebase's `unlink(fromProvider:)` API to unlink a user from an auth provider.
  /// This method will update the UI upon the unlinking's completion.
  /// - Parameter providerID: The string id of the auth provider.
  private func unlinkFromProvider(_ providerID: String) {
    user.unlink(fromProvider: providerID) { user, error in
      guard error == nil else { return self.displayError(error) }
      print("Unlinked user from auth provider: \(providerID)")
      self.updateUI()
    }
  }

  // MARK: - Sign in with Google Account Linking 🔥

  /// This method will initate the Google Sign In flow.
  /// See this class's conformance to `GIDSignInDelegate` below for
  /// context on how the linking is made.
  private func performGoogleAccountLink() {
    guard let clientID = FirebaseApp.app()?.options.clientID else { return }

    // Create Google Sign In configuration object.
    let config = GIDConfiguration(clientID: clientID)

    // Start the sign in flow!
    GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [unowned self] user, error in

      guard error == nil else { return displayError(error) }

      guard
        let authentication = user?.authentication,
        let idToken = authentication.idToken
      else {
        let error = NSError(
          domain: "GIDSignInError",
          code: -1,
          userInfo: [
            NSLocalizedDescriptionKey: "Unexpected sign in result: required authentication data is missing.",
          ]
        )
        return displayError(error)
      }

      let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                     accessToken: authentication.accessToken)

      // Rather than use the credential to sign in the user, we will use it to link to the currently signed in user's account.
      linkAccount(authCredential: credential)
    }
  }

  // MARK: - Sign in with Apple Account Linking 🔥

  // For Sign in with Apple
  var currentNonce: String?

  /// This method will initate the Sign In with Apple flow.
  /// See this class's conformance to `ASAuthorizationControllerDelegate` below for
  /// context on how the linking is made.
  private func performAppleAccountLink() {
    let nonce = randomNonceString()
    currentNonce = nonce
    let appleIDProvider = ASAuthorizationAppleIDProvider()
    let request = appleIDProvider.createRequest()
    request.requestedScopes = [.fullName, .email]
    request.nonce = sha256(nonce)

    let authorizationController = ASAuthorizationController(authorizationRequests: [request])
    authorizationController.delegate = self
    authorizationController.presentationContextProvider = self
    authorizationController.performRequests()
  }

  // MARK: - Twitter, Microsoft, GitHub, Yahoo Account Linking 🔥

  // Maintain a strong reference to an OAuthProvider for login
  private var oauthProvider: OAuthProvider!

  private func performOAuthAccountLink(for provider: AuthProvider) {
    oauthProvider = OAuthProvider(providerID: provider.id)
    oauthProvider.getCredentialWith(nil) { [weak self] credential, error in
      guard let strongSelf = self else { return }
      guard error == nil else { return strongSelf.displayError(error) }
      guard let credential = credential else { return }
      strongSelf.linkAccount(authCredential: credential)
    }
  }

  // MARK: - Sign in with Facebook Account Linking 🔥

  private func performFacebookAccountLink() {
    // The following config can also be stored in the project's .plist
    Settings.appID = "ENTER APP ID HERE"
    Settings.displayName = "AuthenticationExample"

    // Create a Facebook `LoginManager` instance
    let loginManager = LoginManager()
    loginManager.logIn(permissions: ["email"], from: self) { [weak self] result, error in
      guard let strongSelf = self else { return }
      guard error == nil else { return strongSelf.displayError(error) }
      guard let accessToken = AccessToken.current else { return }
      let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
      strongSelf.linkAccount(authCredential: credential)
    }
  }

  // MARK: - Email & Password Login Account Linking 🔥

  private func performEmailPasswordAccountLink() {
    presentEmailPasswordLinkAlertController { [weak self] email, password in
      guard let strongSelf = self else { return }
      let credential = EmailAuthProvider.credential(withEmail: email, password: password)
      strongSelf.linkAccount(authCredential: credential)
    }
  }

  // MARK: - Phone Number Account Linking 🔥

  public func performPhoneNumberAccountLink() {
    presentPhoneNumberAlertController { [weak self] phoneNumber in
      let phoneNumber = String(format: "+%@", phoneNumber)
      PhoneAuthProvider.provider()
        .verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
          guard let strongSelf = self else { return }
          guard error == nil else { return strongSelf.displayError(error) }
          guard let verificationID = verificationID else { return }
          strongSelf.presentPhoneLinkAlertController { verificationCode in
            let credential = PhoneAuthProvider.provider()
              .credential(withVerificationID: verificationID, verificationCode: verificationCode)
            strongSelf.linkAccount(authCredential: credential)
          }
        }
    }
  }

  private func presentPhoneNumberAlertController(linkHandler: @escaping (String) -> Void) {
    presentTextFieldAlertController(
      title: "Link with Phone Auth",
      message: "Example input for +1 (123)456-7890 would be 11234567890",
      textfieldPlaceholder: "Enter a phone number.",
      saveHandler: linkHandler
    )
  }

  private func presentPhoneLinkAlertController(saveHandler: @escaping (String) -> Void) {
    presentTextFieldAlertController(
      title: "Link with Phone Auth",
      textfieldPlaceholder: "Enter verification code.",
      saveHandler: saveHandler
    )
  }

  // MARK: - Email Link/Passwordless Account Linking 🔥

  /// Similar to in `PasswordlessViewController`, enter the authorized domain.
  /// Please refer to this Quickstart's README for more information.
  private let authorizedDomain: String = "ENTER AUTHORIZED DOMAIN"
  /// Maintain a reference to the email entered for linking user to Passwordless.
  private var email: String?

  private func performPasswordlessAccountLink() {
    presentPasswordlessAlertController { [weak self] email in
      guard let strongSelf = self else { return }
      strongSelf.sendSignInLink(to: email)
    }
  }

  private func presentPasswordlessAlertController(saveHandler: @escaping (String) -> Void) {
    presentTextFieldAlertController(
      title: "Link with Passwordless Login",
      message: "Leave this view up while you check your email for the verification link.",
      textfieldPlaceholder: "Enter a valid email address.",
      saveHandler: saveHandler
    )
  }

  private func sendSignInLink(to email: String) {
    let actionCodeSettings = ActionCodeSettings()
    let stringURL = "https://\(authorizedDomain).firebaseapp.com/login?email=\(email)"
    actionCodeSettings.url = URL(string: stringURL)
    // The sign-in operation must be completed in the app.
    actionCodeSettings.handleCodeInApp = true
    actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)

    Auth.auth().sendSignInLink(toEmail: email, actionCodeSettings: actionCodeSettings) { error in
      guard error == nil else { return self.displayError(error) }

      // Set `email` property as it will be used to complete sign in after opening email link
      self.email = email
    }
  }

  @objc
  private func passwordlessSignIn() {
    // Retrieve link that we stored in user defaults in `SceneDelegate`.
    guard let email = email,
      let link = UserDefaults.standard.value(forKey: "Link") as? String else { return }
    let credential = EmailAuthProvider.credential(withEmail: email, link: link)
    linkAccount(authCredential: credential)
    self.email = nil
  }

  private func registerForLoginNotifications() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(passwordlessSignIn),
      name: Notification.Name("PasswordlessEmailNotificationSuccess"),
      object: nil
    )
  }

  // MARK: - UI Configuration

  private func configureNavigationBar() {
    navigationItem.title = "Account Linking"
    navigationItem.backBarButtonItem?.tintColor = .systemYellow
    navigationController?.navigationBar.prefersLargeTitles = true
  }

  private func presentTextFieldAlertController(title: String? = nil,
                                               message: String? = nil,
                                               textfieldPlaceholder: String? = nil,
                                               saveHandler: @escaping (String) -> Void) {
    let textFieldAlertController = UIAlertController(
      title: title,
      message: message,
      preferredStyle: .alert
    )

    textFieldAlertController.addTextField { textfield in
      textfield.placeholder = textfieldPlaceholder
      textfield.textContentType = .oneTimeCode
    }

    let onContinue: (UIAlertAction) -> Void = { _ in
      let text = textFieldAlertController.textFields!.first!.text!
      saveHandler(text)
    }

    textFieldAlertController.addAction(
      UIAlertAction(title: "Continue", style: .default, handler: onContinue)
    )

    textFieldAlertController.addAction(
      UIAlertAction(title: "Cancel", style: .cancel)
    )

    present(textFieldAlertController, animated: true, completion: nil)
  }

  private func presentEmailPasswordLinkAlertController(linkHandler: @escaping (String, String)
    -> Void) {
    let loginAlertController = UIAlertController(
      title: "Link Password Auth",
      message: "Enter a valid email and password to link",
      preferredStyle: .alert
    )

    ["Email", "Password"].forEach { placeholder in
      loginAlertController.addTextField { textfield in
        textfield.placeholder = placeholder
      }
    }

    let onContinue: (UIAlertAction) -> Void = { _ in
      let email = loginAlertController.textFields![0].text!
      let password = loginAlertController.textFields![1].text!
      linkHandler(email, password)
    }

    loginAlertController
      .addAction(UIAlertAction(title: "Continue", style: .default, handler: onContinue))
    loginAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

    present(loginAlertController, animated: true, completion: nil)
  }

  // MARK: - TableView Configuration & Refresh

  private func configureDataSourceProvider() {
    dataSourceProvider = DataSourceProvider(
      dataSource: sections,
      tableView: tableView
    )
    dataSourceProvider.delegate = self
  }

  private func updateUI() {
    configureDataSourceProvider()
    animateUpdates(for: tableView)
  }

  private func animateUpdates(for tableView: UITableView) {
    UIView.transition(with: tableView, duration: 0.05,
                      options: .transitionCrossDissolve,
                      animations: { tableView.reloadData() })
  }
}

// MARK: DataSourceProvidable

extension AccountLinkingViewController: DataSourceProvidable {
  var sections: [Section] { buildSections() }

  private func buildSections() -> [Section] {
    var section = AuthProvider.authLinkSections.first!
    section.items = section.items.compactMap { (item) -> Item? in
      var item = item
      item.hasNestedContent = false
      item.isChecked = userProviderDataContains(item: item)
      return ["Anonymous Authentication", "Custom Auth System"].contains(item.title) ? nil : item
    }
    return [section]
  }

  private func userProviderDataContains(item: Item) -> Bool {
    guard let authProvider = AuthProvider(rawValue: item.title ?? "") else { return false }
    return user.providerData.map { $0.providerID }.contains(authProvider.id)
  }
}

// MARK: - Implementing Sign in with Apple with Firebase

extension AccountLinkingViewController: ASAuthorizationControllerDelegate,
  ASAuthorizationControllerPresentationContextProviding {
  // MARK: ASAuthorizationControllerDelegate

  func authorizationController(controller: ASAuthorizationController,
                               didCompleteWithAuthorization authorization: ASAuthorization) {
    guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential
    else {
      print("Unable to retrieve AppleIDCredential")
      return
    }

    guard let nonce = currentNonce else {
      fatalError("Invalid state: A login callback was received, but no login request was sent.")
    }
    guard let appleIDToken = appleIDCredential.identityToken else {
      print("Unable to fetch identity token")
      return
    }
    guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
      print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
      return
    }

    let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                              idToken: idTokenString,
                                              rawNonce: nonce)
    // Once we have created the above `credential`, we can link accounts to it.
    linkAccount(authCredential: credential)
  }

  func authorizationController(controller: ASAuthorizationController,
                               didCompleteWithError error: Error) {
    // Ensure that you have:
    //  - enabled `Sign in with Apple` on the Firebase console
    //  - added the `Sign in with Apple` capability for this project
    print("Sign in with Apple errored: \(error)")
  }

  // MARK: ASAuthorizationControllerPresentationContextProviding

  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    return view.window!
  }

  // MARK: Aditional `Sign in with Apple` Helpers

  // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
  private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] =
      Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
      let randoms: [UInt8] = (0 ..< 16).map { _ in
        var random: UInt8 = 0
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
        if errorCode != errSecSuccess {
          fatalError(
            "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
          )
        }
        return random
      }

      randoms.forEach { random in
        if remainingLength == 0 {
          return
        }

        if random < charset.count {
          result.append(charset[Int(random)])
          remainingLength -= 1
        }
      }
    }

    return result
  }

  private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
      String(format: "%02x", $0)
    }.joined()

    return hashString
  }
}
