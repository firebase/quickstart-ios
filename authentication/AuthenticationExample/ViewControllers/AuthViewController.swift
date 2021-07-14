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

// For Sign in with Google
import GoogleSignIn

// For Sign in with Facebook
import FBSDKLoginKit

// For Sign in with Apple
import AuthenticationServices
import CryptoKit

private let kFacebookAppID = "ENTER APP ID HERE"

class AuthViewController: UIViewController, DataSourceProviderDelegate {
  var dataSourceProvider: DataSourceProvider<AuthProvider>!

  override func loadView() {
    view = UITableView(frame: .zero, style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureNavigationBar()
    configureDataSourceProvider()
  }

  // MARK: - DataSourceProviderDelegate

  func didSelectRowAt(_ indexPath: IndexPath, on tableView: UITableView) {
    let item = dataSourceProvider.item(at: indexPath)

    let providerName = item.isEditable ? item.detailTitle! : item.title!

    guard let provider = AuthProvider(rawValue: providerName) else {
      // The row tapped has no affiliated action.
      return
    }

    switch provider {
    case .google:
      performGoogleSignInFlow()

    case .apple:
      performAppleSignInFlow()

    case .facebook:
      performFacebookSignInFlow()

    case .twitter, .microsoft, .gitHub, .yahoo:
      performOAuthLoginFlow(for: provider)

    case .emailPassword:
      performDemoEmailPasswordLoginFlow()

    case .passwordless:
      performPasswordlessLoginFlow()

    case .phoneNumber:
      performPhoneNumberLoginFlow()

    case .anonymous:
      performAnonymousLoginFlow()

    case .custom:
      performCustomAuthLoginFlow()
    }
  }

  // MARK: - Firebase 🔥

  private func performGoogleSignInFlow() {
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

      Auth.auth().signIn(with: credential) { result, error in
        guard error == nil else { return self.displayError(error) }

        // At this point, our user is signed in
        // so we advance to the User View Controller
        self.transitionToUserViewController()
      }
    }
  }

  // For Sign in with Apple
  var currentNonce: String?

  private func performAppleSignInFlow() {
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

  private func performFacebookSignInFlow() {
    // The following config can also be stored in the project's .plist
    Settings.appID = kFacebookAppID
    Settings.displayName = "AuthenticationExample"

    // Create a Facebook `LoginManager` instance
    let loginManager = LoginManager()
    loginManager.logIn(permissions: ["email"], from: self) { result, error in
      guard error == nil else { return self.displayError(error) }
      guard let accessToken = AccessToken.current else { return }
      let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
      self.signin(with: credential)
    }
  }

  // Maintain a strong reference to an OAuthProvider for login
  private var oauthProvider: OAuthProvider!

  private func performOAuthLoginFlow(for provider: AuthProvider) {
    oauthProvider = OAuthProvider(providerID: provider.id)
    oauthProvider.getCredentialWith(nil) { credential, error in
      guard error == nil else { return self.displayError(error) }
      guard let credential = credential else { return }
      self.signin(with: credential)
    }
  }

  private func performDemoEmailPasswordLoginFlow() {
    let loginController = LoginController()
    loginController.delegate = self
    navigationController?.pushViewController(loginController, animated: true)
  }

  private func performPasswordlessLoginFlow() {
    let passwordlessViewController = PasswordlessViewController()
    passwordlessViewController.delegate = self
    let navPasswordlessAuthController =
      UINavigationController(rootViewController: passwordlessViewController)
    navigationController?.present(navPasswordlessAuthController, animated: true)
  }

  private func performPhoneNumberLoginFlow() {
    let phoneAuthViewController = PhoneAuthViewController()
    phoneAuthViewController.delegate = self
    let navPhoneAuthController = UINavigationController(rootViewController: phoneAuthViewController)
    navigationController?.present(navPhoneAuthController, animated: true)
  }

  private func performAnonymousLoginFlow() {
    Auth.auth().signInAnonymously { result, error in
      guard error == nil else { return self.displayError(error) }
      self.transitionToUserViewController()
    }
  }

  private func performCustomAuthLoginFlow() {
    let customAuthController = CustomAuthViewController()
    customAuthController.delegate = self
    let navCustomAuthController = UINavigationController(rootViewController: customAuthController)
    navigationController?.present(navCustomAuthController, animated: true)
  }

  private func signin(with credential: AuthCredential) {
    Auth.auth().signIn(with: credential) { result, error in
      guard error == nil else { return self.displayError(error) }
      self.transitionToUserViewController()
    }
  }

  // MARK: - Private Helpers

  private func configureDataSourceProvider() {
    let tableView = view as! UITableView
    dataSourceProvider = DataSourceProvider(dataSource: AuthProvider.sections, tableView: tableView)
    dataSourceProvider.delegate = self
  }

  private func configureNavigationBar() {
    navigationItem.title = "Firebase Auth"
    guard let navigationBar = navigationController?.navigationBar else { return }
    navigationBar.prefersLargeTitles = true
    navigationBar.titleTextAttributes = [.foregroundColor: UIColor.systemOrange]
    navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.systemOrange]
  }

  private func transitionToUserViewController() {
    // UserViewController is at index 1 in the tabBarController.viewControllers array
    tabBarController?.transitionToViewController(atIndex: 1)
  }
}

// MARK: - LoginDelegate

extension AuthViewController: LoginDelegate {
  public func loginDidOccur() {
    transitionToUserViewController()
  }
}

// MARK: - Implementing Sign in with Apple with Firebase

extension AuthViewController: ASAuthorizationControllerDelegate,
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

    Auth.auth().signIn(with: credential) { result, error in
      // Error. If error.code == .MissingOrInvalidNonce, make sure
      // you're sending the SHA256-hashed nonce as a hex string with
      // your request to Apple.
      guard error == nil else { return self.displayError(error) }

      // At this point, our user is signed in
      // so we advance to the User View Controller
      self.transitionToUserViewController()
    }
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
