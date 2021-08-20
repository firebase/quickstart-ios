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

struct MainView: View {
  @StateObject var process = Process()
  var body: some View {
    NavigationView {
      VStack {
        process.status.view
        List {
          NavigationLink("Download Image", destination: DownloadView(process: process))
          NavigationLink("Classify Image", destination: ClassifyView(process: process))
          NavigationLink("Generate Saliency Map", destination: SaliencyMapView(process: process))
          NavigationLink("Upload Saliency Map", destination: UploadView(process: process))
        }
      }
      .navigationTitle("Performance")
    }
  }
}

struct MainView_Previews: PreviewProvider {
  static var previews: some View {
    MainView()
  }
}
