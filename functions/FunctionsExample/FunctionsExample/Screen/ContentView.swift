//
//  Copyright 2022 Google LLC
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
