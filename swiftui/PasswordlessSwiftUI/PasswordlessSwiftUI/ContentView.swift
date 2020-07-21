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

import SwiftUI
import Firebase


/// Main view where user can login in using Email Link Authentication.
struct ContentView: View {
  @State private var email: String = ""
  @State private var isPresentingSheet = false

  var body: some View {

    NavigationView {
      VStack(alignment: .leading) {
        Text("Authenticate users with only their email, no password required!")
          .padding(.bottom, 60)

        CustomStyledTextField(
          text: $email, placeholder: "Email", symbolName: "person.circle.fill"
        )

        CustomStyledButton(title: "Send Sign In Link") {
          sendSignInLink()
        }
        .disabled(email.isEmpty)

        Spacer()
      }
      .padding()
      .navigationBarTitle("Passwordless Login")
    }
    .onOpenURL { (url) in
      let link = url.absoluteString
      if Auth.auth().isSignIn(withEmailLink: link) {
        passwordlessSignIn(email: email, link: link) { user, error in
          isPresentingSheet = user?.isEmailVerified ?? false
        }
      }
    }
    .sheet(isPresented: $isPresentingSheet) {
      SuccessView(email: $email)
    }
  }

  // MARK: - Firebase 🔥

  private func sendSignInLink() {
    let actionCodeSettings = ActionCodeSettings()
    actionCodeSettings.url = URL(string: "https://passwordlessswiftui.page.link/demo_login")
    actionCodeSettings.handleCodeInApp = true
    actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)

    Auth.auth().sendSignInLink(toEmail: email, actionCodeSettings: actionCodeSettings)
  }

  private func passwordlessSignIn(email: String, link: String,
                                  completion: @escaping (_ user: User?, _ error: Error?) -> ()) {
    Auth.auth().signIn(withEmail: email, link: link) { result, error in
      print(error ?? "Authentication was successful.")
      let newUser = error == nil ? Auth.auth().currentUser : nil
      completion(newUser, error)
    }
  }
}

/// A custom styled TextField with an SF symbol icon.
struct CustomStyledTextField: View {
  @Binding var text: String
  let placeholder: String
  let symbolName: String
  
  var body: some View {
    HStack {
      Image(systemName: symbolName)
        .imageScale(.large)
        .padding(.leading)
      
      TextField(placeholder, text: $text)
        .padding(.vertical)
        .accentColor(.orange)
        .autocapitalization(.none)
    }
    .background(
      RoundedRectangle(cornerRadius: 16.0, style: .circular)
      .foregroundColor(Color(.secondarySystemFill))
    )
  }
}

/// A custom styled button with a custom title and action.
struct CustomStyledButton: View {
  let title: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Spacer()
      Text(title)
        .padding()
        .accentColor(.white)
      Spacer()
    }
    .background(Color.orange)
    .cornerRadius(16.0)
  }

}

/// Displayed when a user successfuly logs in.
struct SuccessView: View {
  @Binding var email: String
  
  var body: some View {
    /// The first view in this `ZStack` is a `Color` view that expands
    /// to set the background color of the `SucessView`.
    ZStack {
      Color.orange
        .edgesIgnoringSafeArea(.all)
        
      VStack(alignment: .leading) {
        Group {
          Text("Welcome")
            .font(.largeTitle)
            .fontWeight(.semibold)
          
          Text(email.lowercased())
            .font(.title3)
            .fontWeight(.bold)
            .multilineTextAlignment(.leading)
        }
        .padding(.leading)
        
        Image(systemName: "checkmark.circle")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .scaleEffect(0.5)
      }
      .foregroundColor(.white)
    }
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
                               completion: @escaping (_ user: User?, _ error: Error?) -> ()) -> some View {
      self.onOpenURL { (url) in
        let link = url.absoluteString
        if Auth.auth().isSignIn(withEmailLink: link) {
          Auth.auth().signIn(withEmail: email, link: link) { result, error in
            print(error ?? "Authentication was successful.")
            let newUser = error == nil ? Auth.auth().currentUser : nil
            completion(newUser, error)
          }
        }
      }
    }
}

