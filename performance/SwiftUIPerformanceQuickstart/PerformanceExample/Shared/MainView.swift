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

struct EmptyView: View {
  var body: some View {
    Text("Hello, World!")
  }
}

struct MainView: View {
  @StateObject var process = Process()
  @State var image: Image
  var body: some View {
    NavigationView {
      HStack {
        Spacer()
        List {
          NavigationLink("Download Image", destination: EmptyView())
          NavigationLink("Modify Image", destination: EmptyView())
          NavigationLink("Upload Image", destination: EmptyView())
        }
        .navigationTitle("Performance")
        .toolbar {
          ToolbarItem(placement: .principal) {
            HStack {
              ProgressView()
              Text("  Running")
            }
          }
        }
        Spacer()
      }
    }
  }
}

struct MainView_Previews: PreviewProvider {
  static var previews: some View {
    MainView(image: Image(systemName: "star"))
  }
}
