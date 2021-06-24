//
//  CrashlyticsSwiftUIExampleApp.swift
//  Shared
//
//  Created by Judy Liu on 6/23/21.
//  Copyright © 2021 Google Inc. All rights reserved.
//

import SwiftUI
import Firebase

@main
struct CrashlyticsSwiftUIExampleApp: App {

    init() {
      FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
