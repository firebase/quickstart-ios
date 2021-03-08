//
//  FirestoreSwiftUIExampleApp.swift
//  FirestoreSwiftUIExample
//

import SwiftUI
import Firebase

@main
struct FirestoreSwiftUIExampleApp: App {

  init() {
    FirebaseApp.configure()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
