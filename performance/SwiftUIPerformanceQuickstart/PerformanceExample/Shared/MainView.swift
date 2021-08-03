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

struct ImageClassifierView: View {
  @ObservedObject var process: Process

  var body: some View {
    VStack {
      if let uiImage = process.image {
        Image(uiImage: uiImage).padding(.bottom)
        if process.action == .classify {
          if let categories = process.categories {
            if categories.isEmpty {
              Text("No categories found with a recall precision of \(process.precision)!")
            } else {
              Text("Categories found:")
              List(categories, id: \.category) { category, confidence in
                Text("\(category): \(confidence)")
              }
            }
          } else {
            Button("Classify Image") {
              if #available(iOS 15, tvOS 15, *) {
                #if swift(>=5.5)
                  Task { await process.classifyImageAsync() }
                #else
                  process.classifyImage()
                #endif
              } else {
                process.classifyImage()
              }
            }
          }
        }
      } else {
        Image(systemName: "questionmark.square").padding(.bottom)
        if process.action != .download {
          Text("No image found!\nPlease download an image first.")
            .multilineTextAlignment(.center)
        }
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) { process.status.view }
    }
  }
}

struct MainView: View {
  @StateObject var process = Process()

  var body: some View {
    NavigationView {
      List(ProcessAction.allCases, id: \.rawValue) { action in
        NavigationLink(
          "\(action.rawValue) Image",
          destination: ImageClassifierView(process: process).onAppear {
            if #available(iOS 15, tvOS 15, *) {
              #if swift(>=5.5)
                process.updateActionAsync(to: action)
              #endif
            } else {
              process.updateAction(to: action)
            }
            if action == .download, process.status == .idle {
              if #available(iOS 15, tvOS 15, *) {
                #if swift(>=5.5)
                  Task { await process.downloadImageAsync() }
                #endif
              } else {
                process.downloadImage()
              }
            }
          }
        )
      }
      .navigationTitle("Performance")
      .toolbar {
        ToolbarItem(placement: .principal) { process.status.view }
      }
    }
  }
}

struct MainView_Previews: PreviewProvider {
  @StateObject static var process = Process()
  static var previews: some View {
    MainView()
    ImageClassifierView(process: process)
  }
}
