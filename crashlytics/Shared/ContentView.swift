//
//  ContentView.swift
//  Shared
//
//  Created by Judy Liu on 6/23/21.
//  Copyright © 2021 Google Inc. All rights reserved.
//

import SwiftUI

struct ContentView: View {
  var body: some View {
    NavigationView {
        Button("Crash", action:  {
          fatalError()
        })
        .font(.largeTitle)
        .padding()
        .background(Color.red)
        .foregroundColor(.white)
        .clipShape(Capsule())
        .navigationTitle("Crashlytics Example")
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
