//
//  FirestoreSwiftUIExampleApp.swift
//  FirestoreSwiftUIExample
//
//  Created by Rachel Collins on 2/26/21.
//  Copyright © 2021 Firebase. All rights reserved.
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
