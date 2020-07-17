//
//  ContentView.swift
//  PasswordlessSwiftUI
//
//  Copyright © 2020 Google LLC. All rights reserved.
//

import SwiftUI
import Firebase


/// Main view where user can login in using Email Link Authentication.
struct ContentView: View {
  @State private var email: String = ""
  @State private var presentSheet = false

  var body: some View {

    NavigationView {
      VStack(spacing: 50.0) {
        Text("Authenticate users with only their email, no password required!")
          .frame(maxWidth: .infinity, alignment: .leading)
        
        Spacer()
          .frame(height: 0.0)
        
        CustomStyledTextField(
          text: $email, placeholder: "Email", symbol: "person.circle.fill"
        )

        CustomStyledButton(title: "Send Sign In Link") {
          sendSignInLink(to: email)
        }

        Spacer()
      }
      .padding()
      .navigationBarTitle("Passwordless Login")

    }
    .onOpenURL { (url) in
      let link = url.absoluteString
      if Auth.auth().isSignIn(withEmailLink: link) {
        passwordlessSignIn(email: email, link: link) { (success) in
          self.presentSheet = success
        }
      }
    }
    .sheet(isPresented: $presentSheet) {
      SuccessView(email: $email)
    }

  }

}

/// A custom styled TextField with an SF symbol icon.
struct CustomStyledTextField: View {
  @Binding var text: String
  let placeholder: String
  let symbol: String
  
  var body: some View {
    HStack {
      Spacer()
        .frame(width: 15.0)

      Image(systemName: symbol)
        .imageScale(.large)
      
      TextField(placeholder, text: $text)
        .padding([.top, .bottom])
        .accentColor(.orange)
    }
    .autocapitalization(.none)
    .background(
      RoundedRectangle(cornerRadius: 16.0, style: .circular)
      .foregroundColor(
        Color(.secondarySystemFill)
      )
    )
  }
}

/// A custom styled button with a custom title and action.
struct CustomStyledButton: View {
  let title: String
  let action: () -> Void

  var body: some View {
    Button(title, action: action)
    .padding()
    .frame(maxWidth: .infinity)
    .accentColor(.white)
    .background(Color.orange)
    .cornerRadius(16.0)
  }

}

/// Displayed when a user successfuly logs in.
struct SuccessView: View {
  @Binding var email: String
  
  var body: some View {
    ZStack {
      Color.orange
        .edgesIgnoringSafeArea(.all)
        
      VStack {
        Group {
          Text("Welcome")
            .font(.largeTitle)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, alignment: .leading)
          
          Text(email.lowercased())
            .font(.title3)
            .fontWeight(.bold)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading)
        
        Image(systemName: "checkmark.circle")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .scaleEffect(0.5, anchor: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
      }
      .foregroundColor(.white)
    }
  }
}


// MARK: - Firebase 🔥

private func sendSignInLink(to email: String) {
  let actionCodeSettings = ActionCodeSettings()
  actionCodeSettings.url = URL(string: "https://passwordlessswiftui.page.link/demo_login")
  actionCodeSettings.handleCodeInApp = true
  actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)

  Auth.auth().sendSignInLink(toEmail: email, actionCodeSettings: actionCodeSettings)
}

private func passwordlessSignIn(email: String, link: String,
                                completion: @escaping (_ success: Bool)->()) {
  Auth.auth().signIn(withEmail: email, link: link) { result, error in
    guard error == nil, let currentUser = Auth.auth().currentUser else {
      completion(false)
      return print(error!)
    }

    completion(currentUser.isEmailVerified)
  }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
      ContentView()
    }
}

// MARK: Example Auth View Modifier

extension View {
  func handlePasswordlessLogin(forEmail email: String,
                               completion: @escaping (Bool)->()) -> some View {
      self.onOpenURL { (url) in
        let link = url.absoluteString
        if Auth.auth().isSignIn(withEmailLink: link) {
          passwordlessSignIn(email: email, link: link) { (success) in
            completion(success)
          }
        } else {
          completion(false)
        }
      }
    }
}
