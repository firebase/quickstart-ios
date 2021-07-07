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
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  var screenWidth = UIScreen.main.bounds.width
  var screenHeight = UIScreen.main.bounds.height

  var body: some View {
    VStack {
      // Sign up title
      Text("Sign up".uppercased())
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

      // Sign up button
      Button(action: user.signUp) {
        Text("Sign up".uppercased())
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
        Text("Already have an account?")
        Button(action: {
          self.presentationMode.wrappedValue.dismiss()
        }) {
          Text("Login".uppercased())
            .bold()
        }
      }
      if user.isLoading {
        LoadingView()
      }
    }
    .alert(isPresented: $user.alert, content: {
      Alert(
        title: Text("Message"),
        message: Text(user.alertMessage),
        dismissButton: .destructive(Text("Ok"))
      )
    })
    .navigationBarHidden(true)
  }
}

struct SignUpView_Previews: PreviewProvider {
  static var previews: some View {
    SignUpView(user: user)
      .preferredColorScheme(.light)
  }
}
