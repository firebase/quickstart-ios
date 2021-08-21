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

struct SaliencyMapView: View {
  @ObservedObject var process: Process
  var body: some View {
    VStack {
      process.status.view
      Spacer()
      if let image = process.image {
        if let saliencyMap = process.saliencyMap {
          Image(uiImage: saliencyMap).padding(.bottom)
          Text("Saliency map generated successfully!")
        } else {
          Image(uiImage: image).padding(.bottom)
          Button("Generate Saliency Map") {
            if !process.isRunning {
              if #available(iOS 15, tvOS 15, *) {
                #if swift(>=5.5)
                  Task { await process.generateSaliencyMapAsync() }
                #else
                  process.generateSaliencyMap()
                #endif
              } else {
                process.generateSaliencyMap()
              }
            }
          }
          .disabled(process.isRunning)
        }
      } else {
        Image(systemName: "questionmark.square").padding(.bottom)
        Text("No image found!\nPlease download an image first.")
          .multilineTextAlignment(.center)
      }
      Spacer()
    }
  }
}

struct SaliencyMapView_Previews: PreviewProvider {
  @StateObject static var process = Process()
  static var previews: some View {
    SaliencyMapView(process: process)
  }
}
