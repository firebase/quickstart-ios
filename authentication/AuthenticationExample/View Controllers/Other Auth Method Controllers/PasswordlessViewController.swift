//
//  PasswordlessViewController.swift
//  Swifty Auth
//
//  Created by Nicholas Cooke on 6/19/20.
//  Copyright © 2020 Firebase. All rights reserved.
//

import UIKit
import Firebase


class PasswordlessViewController: OtherAuthViewController {
    
    private var email: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI(for: .Passwordless)
        registerForLoginNotifications()
    }
    
    override func buttonTapped() {
        guard let email = textField.text, !email.isEmpty else { return }
        sendSignInLink(to: email)
    }
    
    // MARK: - Firebase 🔥
    
    private func sendSignInLink(to email: String) {
        
        let actionCodeSettings = ActionCodeSettings()
        let stringURL = String(format: "https://swifty-auth.firebaseapp.com/login?email=%@", email)
        actionCodeSettings.url = URL(string: stringURL)
        // The sign-in operation must be completed in the app.
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
        
        Auth.auth().sendSignInLink(toEmail: email, actionCodeSettings: actionCodeSettings) { (error) in
            guard error == nil else { return self.displayError(error) }
            
            // Set `email` property as it will be used to complete sign in after opening email link
            self.email = email
        }
    }
    
    @objc
    private func passwordlessSignIn() {
        // Retrieve link that we stored in user defaults in `SceneDelegate`
        guard let link = UserDefaults.standard.value(forKey: "Link") as? String else { return }
        
        Auth.auth().signIn(withEmail: self.email, link: link) { (result, error) in
            guard error == nil else { return self.displayError(error) }

            guard let currentUser = Auth.auth().currentUser else { return }
            
            if currentUser.isEmailVerified {
                print("User verified with passwordless email.")
                
                self.navigationController?.dismiss(animated: true, completion: {
                    self.delegate?.loginDidOccur()
                })
            } else {
                print("User could not be verified by passwordless email")
            }
            
        }
    }
    
    // MARK: - Private Helpers
    
    private func registerForLoginNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(passwordlessSignIn), name: Notification.Name("PasswordlessEmailNotificationSuccess"), object: nil)
    }
}
