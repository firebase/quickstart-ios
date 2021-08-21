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

enum ProcessTask: String {
  case download = "Download"
  case classify = "Classification"
  case saliencyMap = "Saliency Map"
  case upload = "Upload"
}

enum ProcessStatus: Equatable {
  case idle
  case running(ProcessTask)
  case failure(ProcessTask)
  case success(ProcessTask)

  var text: String {
    switch self {
    case .idle:
      return "⏸ Idle"
    case let .running(task):
      return "\(task.rawValue) Running"
    case let .failure(task):
      return "❌ \(task.rawValue) Failure"
    case let .success(task):
      return "✅ \(task.rawValue) Success"
    }
  }

  var view: some View {
    HStack {
      switch self {
      case .running:
        ProgressView()
        Text(text)
      case .idle, .failure, .success:
        Text(text)
      }
    }
  }
}
