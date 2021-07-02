//
//  Copyright (c) 2018 Google Inc.
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

import Firebase
import FirebaseAuthUI
import FirebaseGoogleAuthUI

private let kFirebaseTermsOfService = URL(string: "https://firebase.google.com/terms/")!

@objc(SignInViewController)
class SignInViewController: UIViewController, FUIAuthDelegate {
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if Auth.auth().currentUser != nil {
      let appDelegate = UIApplication.shared.delegate as? AppDelegate
      appDelegate?.window?.rootViewController = UIStoryboard(name: "Main", bundle: Bundle.main)
        .instantiateInitialViewController()
      dismiss(animated: true, completion: nil)
      return
    }
    let authUI = FUIAuth.defaultAuthUI()
    authUI?.delegate = self
    authUI?.tosurl = kFirebaseTermsOfService
    authUI?.providers = [FUIGoogleAuth()]
    let authViewController: UINavigationController? = authUI?.authViewController()
    authViewController?.navigationBar.isHidden = true
    present(authViewController!, animated: true, completion: nil)
  }

  func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
    switch error {
    case let .some(error as NSError)
      where UInt(error.code) == FUIAuthErrorCode.userCancelledSignIn.rawValue:
      print("User cancelled sign-in")
    case let .some(error as NSError) where error.userInfo[NSUnderlyingErrorKey] != nil:
      print("Login error: \(error.userInfo[NSUnderlyingErrorKey]!)")
    case let .some(error):
      print("Login error: \(error.localizedDescription)")
    case .none:
      if let user = authDataResult?.user {
        signed(in: user)
      }
    }
  }

  func authPickerViewController(forAuthUI authUI: FUIAuth) -> FUIAuthPickerViewController {
    return FAuthPickerViewController(
      nibName: "FAuthPickerViewController",
      bundle: Bundle.main,
      authUI: authUI
    )
  }

  func signed(in user: User) {
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    appDelegate?.window?.rootViewController = UIStoryboard(name: "Main", bundle: Bundle.main)
      .instantiateInitialViewController()
    dismiss(animated: true, completion: nil)
  }
}
