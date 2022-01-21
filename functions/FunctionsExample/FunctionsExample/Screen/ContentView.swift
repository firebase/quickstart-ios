//
//  ContentView.swift
//  FunctionsExample
//
//  Created by Gran Luo on 1/12/22.
//

import SwiftUI
import Firebase

struct ContentView: View {
  var body: some View {
    VStack(alignment: .leading) {
      Image("logo")
        .resizable()
        .scaledToFit()
        .frame(width: ScreenDimensions.width * 0.5)
        .offset(x: 20, y: 0)
      VStack {
        AddNumbers()
        AddMessage()
        Spacer()
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ForEach(
      ["iPhone SE (2nd generation)", "iPhone 13 Pro Max", "iPad Pro (12.9-inch) (5th generation)"],
      id: \.self
    ) { deviceName in
      ContentView()
        .previewDevice(PreviewDevice(rawValue: deviceName))
        .previewDisplayName(deviceName)
    }
  }
}
