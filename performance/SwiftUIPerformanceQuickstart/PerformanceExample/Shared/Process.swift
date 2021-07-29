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

class Process: ObservableObject {
  @Published var status: ProcessStatus = .idle
  @Published var image: Image?

  func updateStatus(status newStatus: ProcessStatus) {}

  func downloadImage() {}
  func modifyImage() {}
  func uploadImage() {}
}

enum ProcessStatus {
  case idle, running, failure, success

  var view: some View {
    HStack {
      switch self {
      case .idle:
        Text("⏸ Idle")
      case .running:
        ProgressView().padding(.trailing, 1.0)
        Text("Running")
      case .failure:
        Text("❌ Failure")
      case .success:
        Text("✅ Success")
      }
    }
  }
}
