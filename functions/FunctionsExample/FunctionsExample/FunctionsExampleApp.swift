//
//  FunctionsExampleApp.swift
//  FunctionsExample
//
//  Created by Gran Luo on 1/12/22.
//

import SwiftUI
import Firebase

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

