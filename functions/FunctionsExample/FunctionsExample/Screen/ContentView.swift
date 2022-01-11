//
//  ContentView.swift
//  FunctionsExample
//
//  Created by Gran Luo on 11/15/21.
//

import SwiftUI
import Firebase

struct ContentView: View {
  @AppStorage("signin") var isSignInViewActive: Bool = true

    var body: some View {
      if isSignInViewActive {
        SignInView().navigationBarHidden(true)
      } else {
        HomeView()
      }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
