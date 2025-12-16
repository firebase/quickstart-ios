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

struct DownloadView: View {
  @ObservedObject var process: Process
  var body: some View {
    VStack {
      process.status.view
      Spacer()
      if let uiImage = process.image {
        Image(uiImage: uiImage).padding(.bottom)
        Text("Image downloaded successfully!")
      } else {
        Image(systemName: "questionmark.square").padding(.bottom)
        Text("No image found!\nPlease download an image first.")
          .multilineTextAlignment(.center)
          .padding(.bottom)
        Button("Download Image") {
          if !process.isRunning {
            if #available(iOS 15, tvOS 15, *) {
              #if swift(>=5.5)
                Task { await process.downloadImageAsync() }
              #else
                process.downloadImage()
              #endif
            } else {
              process.downloadImage()
            }
          }
        }
        .disabled(process.isRunning)
      }
      Spacer()
    }
  }
}

struct DownloadView_Previews: PreviewProvider {
  @StateObject static var process = Process()
  static var previews: some View {
    DownloadView(process: process)
  }
}
