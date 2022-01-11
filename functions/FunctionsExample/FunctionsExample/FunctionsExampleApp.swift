//
//  FunctionsExampleApp.swift
//  FunctionsExample
//
//  Created by Gran Luo on 11/15/21.
//

import SwiftUI
import Firebase
import FirebaseAuthUI

@main
struct FunctionsExampleApp: App {
  init() {
    FirebaseApp.configure()
  }
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
