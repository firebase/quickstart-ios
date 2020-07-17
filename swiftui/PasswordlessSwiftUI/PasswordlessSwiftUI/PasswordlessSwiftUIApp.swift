//
//  PasswordlessSwiftUIApp.swift
//  PasswordlessSwiftUI
//
//  Copyright © 2020 Google LLC. All rights reserved.
//

import SwiftUI
import Firebase

@main
struct PasswordlessSwiftUIApp: App {

  init() {
    FirebaseApp.configure()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
