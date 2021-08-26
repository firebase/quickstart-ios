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

struct UploadView: View {
  @ObservedObject var process: Process
  var body: some View {
    VStack {
      process.status.view
      Spacer()
      if let saliencyMap = process.saliencyMap {
        Image(uiImage: saliencyMap).padding(.bottom)
        if process.uploadSucceeded {
          Text("Saliency map uploaded successfully!")
        } else {
          Button("Upload Saliency Map") {
            if !process.isRunning {
              if #available(iOS 15, tvOS 15, *) {
                #if swift(>=5.5)
                  Task { await process.uploadSaliencyMapAsync() }
                #else
                  process.uploadSaliencyMap()
                #endif
              } else {
                process.uploadSaliencyMap()
              }
            }
          }
          .disabled(process.isRunning)
        }
      } else {
        Image(systemName: "questionmark.square").padding(.bottom)
        Text("No saliency map found!\nPlease download an image and generate a saliency map first.")
          .multilineTextAlignment(.center)
          .padding(.horizontal)
      }
      Spacer()
    }
  }
}

struct UploadView_Previews: PreviewProvider {
  @StateObject static var process = Process()
  static var previews: some View {
    UploadView(process: process)
  }
}
