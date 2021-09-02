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

struct SignUpView: View {
  @ObservedObject var user: UserViewModel
  @Binding var isPresented: Bool

  var body: some View {
    let signUpView = VStack {
      // Sign up title
      Text("Sign up".uppercased())
        .font(.title)

      Spacer()
        .frame(idealHeight: 0.1 * ScreenDimensions.height)
        .fixedSize()

      // Email textfield
      let emailInputField = HStack {
        Image("user-icon")
          .resizable()
          .scaledToFit()
          .frame(width: 30.0, height: 30.0)
          .opacity(0.5)
        let emailTextField = TextField("Email", text: $user.email)
        #if os(iOS)
          emailTextField
            .keyboardType(.emailAddress)
            .autocapitalization(UITextAutocapitalizationType.none)
        #elseif os(macOS) || os(tvOS)
          emailTextField
        #endif
      }
      .padding(0.02 * ScreenDimensions.height)

      #if os(iOS)
        emailInputField
          .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray5)))
          .frame(width: ScreenDimensions.width * 0.8)
      #elseif os(macOS) || os(tvOS)
        emailInputField
      #endif

      // Password textfield
      let passwordInputField = HStack {
        Image("lock-icon")
          .resizable()
          .scaledToFit()
          .frame(width: 30.0, height: 30.0)
          .opacity(0.5)
        SecureField("Password", text: $user.password)
      }
      .padding(0.02 * ScreenDimensions.height)

      #if os(iOS)
        passwordInputField
          .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray5)))
          .frame(width: ScreenDimensions.width * 0.8)
      #elseif os(macOS) || os(tvOS)
        passwordInputField
      #endif

      Spacer()
        .frame(idealHeight: 0.05 * ScreenDimensions.height)
        .fixedSize()

      // Sign up button
      let signUpButton = Button(action: user.signUp) {
        Text("Sign up".uppercased())
          .foregroundColor(.white)
          .font(.title2)
          .bold()
      }
      .padding(0.025 * ScreenDimensions.height)
      .background(Capsule().fill(Color(.systemTeal)))

      #if os(iOS) || os(macOS)
        signUpButton
          .buttonStyle(BorderlessButtonStyle())
      #elseif os(tvOS)
        signUpButton
      #endif

      Spacer()
        .frame(idealHeight: 0.05 * ScreenDimensions.height)
        .fixedSize()

      // Navigation text
      HStack {
        Text("Already have an account?")
        let loginButton = Button(action: {
          isPresented = false
        }) {
          Text("Login".uppercased())
            .bold()
        }

        #if os(iOS) || os(macOS)
          loginButton
            .buttonStyle(BorderlessButtonStyle())
        #elseif os(tvOS)
          loginButton
        #endif
      }
    }
    .alert(isPresented: $user.alert, content: {
      Alert(
        title: Text("Message"),
        message: Text(user.alertMessage),
        dismissButton: .destructive(Text("Ok"))
      )
    })
    #if os(iOS) || os(tvOS)
      signUpView
    #elseif os(macOS)
      signUpView
        .frame(minWidth: 400, idealWidth: 400, minHeight: 700, idealHeight: 700)
    #endif
  }
}

struct SignUpView_Previews: PreviewProvider {
  static var previews: some View {
    SignUpView(user: user, isPresented: .constant(false))
      .preferredColorScheme(.light)
  }
}
