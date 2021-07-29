//
//  Copyright 2021 Google LLC
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

struct ImageView: View {
  @ObservedObject var process: Process
  var body: some View {
    VStack {
      if let image = process.image {
        image.padding(.bottom)
      } else {
        Image(systemName: "questionmark.square").padding(.bottom)
      }
      Button("Modify Image") { process.modifyImage() }
    }
  }
}

struct MainView: View {
  @StateObject var process = Process()
  let actions = ["Download", "Modify", "Upload"]

  var body: some View {
    NavigationView {
      HStack {
        Spacer()
        List(actions, id: \.description) { action in
          NavigationLink("\(action) Image", destination: ImageView(process: process))
        }
        .navigationTitle("Performance")
        .toolbar {
          ToolbarItem(placement: .principal) { process.status.view }
        }
        Spacer()
      }
    }
  }
}

struct MainView_Previews: PreviewProvider {
  @StateObject static var process = Process()
  static var previews: some View {
    MainView()
    ImageView(process: process)
  }
}
