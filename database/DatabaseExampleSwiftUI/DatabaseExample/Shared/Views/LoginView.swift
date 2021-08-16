//
//  Copyright (c) 2021 Google Inc.
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

import SwiftUI
import Firebase

struct LoginView: View {
  @StateObject var user = UserViewModel()
  #if os(iOS)
  let screenWidth = UIScreen.main.bounds.width
  let screenHeight = UIScreen.main.bounds.height
  #endif

  #if os(iOS)
  var body: some View {
    NavigationView {
      VStack {
        // Login title
        Text("Login".uppercased())
          .font(.title)

        Spacer()
          .frame(idealHeight: 0.1 * screenHeight)
          .fixedSize()

        // Email textfield
        HStack {
          Image("user-icon")
            .resizable()
            .scaledToFit()
            .frame(width: 30.0, height: 30.0)
            .opacity(0.5)
          TextField("Email", text: $user.email)
            .keyboardType(.emailAddress)
            .autocapitalization(UITextAutocapitalizationType.none)
        }
        .padding(0.02 * screenHeight)
        .frame(
          width: screenWidth * 0.8,
          alignment: /*@START_MENU_TOKEN@*/ .center/*@END_MENU_TOKEN@*/
        )
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray5)))

        // Password textfield
        HStack {
          Image("lock-icon")
            .resizable()
            .scaledToFit()
            .frame(width: 30.0, height: 30.0)
            .opacity(0.5)
          SecureField("Password", text: $user.password)
        }
        .padding(0.02 * screenHeight)
        .frame(width: screenWidth * 0.8, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray5)))

        Spacer()
          .frame(idealHeight: 0.05 * screenHeight)
          .fixedSize()

        // Login button
        Button(action: user.login) {
          Text("Login".uppercased())
            .foregroundColor(.white)
            .font(.title2)
            .bold()
        }
        .padding(0.025 * screenHeight)
        .frame(width: screenWidth * 0.8, alignment: .center)
        .background(Capsule().fill(Color(.systemTeal)))

        Spacer()
          .frame(idealHeight: 0.05 * screenHeight)
          .fixedSize()

        // Navigation text
        HStack {
          Text("Don't have an account?")
          NavigationLink(destination: SignUpView(user: user)) {
            Text("Sign up".uppercased())
              .bold()
          }
        }
      }
      .navigationBarHidden(true)
    }
    .alert(isPresented: $user.alert, content: {
      Alert(
        title: Text("Message"),
        message: Text(user.alertMessage),
        dismissButton: .destructive(Text("OK"))
      )
    })
  }
  #elseif os(macOS)
  @State private var signUpViewPresented = false
  var body: some View {
      VStack {
        // Login title
        Text("Login".uppercased())
          .font(.title)
          .padding(20)

        Spacer()

        // Email textfield
        HStack {
          Image("user-icon")
            .resizable()
            .scaledToFit()
            .frame(width: 30.0, height: 30.0)
            .opacity(0.5)
          TextField("Email", text: $user.email)
        }
        .padding(20)
        .frame(
          width: 300,
          alignment: .center
        )

        // Password textfield
        HStack {
          Image("lock-icon")
            .resizable()
            .scaledToFit()
            .frame(width: 30.0, height: 30.0)
            .opacity(0.5)
          SecureField("Password", text: $user.password)
        }
        .padding(20)
        .frame(
          width: 300,
          alignment: .center
        )

        Spacer()

        // Login button
        Button(action: user.login) {
          Text("Login".uppercased())
            .font(.title2)
            .bold()
        }

        Spacer()

        // Navigation text
        HStack {
          Text("Don't have an account?")
          Button("Sign up".uppercased()) {
            signUpViewPresented = true
          }
          .sheet(isPresented: $signUpViewPresented) {
            SignUpView(user: user, isPresented: $signUpViewPresented)
          }
        }
        .padding(20)
      }
    .alert(isPresented: $user.alert, content: {
      Alert(
        title: Text("Message"),
        message: Text(user.alertMessage),
        dismissButton: .destructive(Text("OK"))
      )
    })
  }
  #endif
}

struct LoginView_Previews: PreviewProvider {
  static var previews: some View {
    LoginView(user: user)
  }
}
