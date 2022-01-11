//
//  SignInView.swift
//  FunctionsExample
//
//  Created by Gran Luo on 11/16/21.
//

import SwiftUI
import Firebase
import FirebaseAuthUI
import FirebaseGoogleAuthUI

struct SignInView: View {

  @AppStorage("signin") var isSignInViewActive: Bool = true

  @State private var viewState = CGSize(width: 0, height: ScreenDimensions.height)
  @State private var MainviewState = CGSize.zero

  var body: some View {
    CustomLoginViewController { (error) in
      if error == nil {
        isSignInViewActive = false
      }
    }.offset(y: self.MainviewState.height)
      .navigationBarHidden(true)
      .padding()

  }
}

struct SignInView_Previews: PreviewProvider {
  static var previews: some View {
    SignInView()
  }
}


struct CustomLoginViewController : UIViewControllerRepresentable {

  var dismiss : (_ error : Error? ) -> Void

  func makeCoordinator() -> CustomLoginViewController.Coordinator {
    Coordinator(self)
  }

  func makeUIViewController(context: Context) -> UIViewController
  {
    let authUI = FUIAuth.defaultAuthUI()!

    let providers : [FUIAuthProvider] = [
      FUIGoogleAuth(authUI: authUI)
    ]

    authUI.providers = providers
    authUI.delegate = context.coordinator
    authUI.shouldHideCancelButton = true


    let authViewController = authUI.authViewController()

    return authViewController
  }

  func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<CustomLoginViewController>)
  {

  }

  //coordinator
  class Coordinator : NSObject, FUIAuthDelegate {
    var parent : CustomLoginViewController

    init(_ customLoginViewController : CustomLoginViewController) {
      self.parent = customLoginViewController
    }

    // MARK: FUIAuthDelegate
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?)
    {
      if let error = error {
        parent.dismiss(error)
      }
      else {
        parent.dismiss(nil)
      }
    }

    func authUI(_ authUI: FUIAuth, didFinish operation: FUIAccountSettingsOperationType, error: Error?)
    {
    }
  }
}
