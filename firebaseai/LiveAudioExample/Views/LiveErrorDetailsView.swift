// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import FirebaseAI
import MarkdownUI
import SwiftUI

struct LiveErrorDetailsView: View {
  var error: Error

  var body: some View {
    NavigationView {
      Form {
        Section("Error type") {
          Text("\(error.self)")
        }

        Section("Details") {
          SubtitleFormRow(title: "Error description", value: error.localizedDescription)
        }
      }
      .navigationTitle("Error details")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

private struct SubtitleFormRow: View {
  var title: String
  var value: String

  var body: some View {
    VStack(alignment: .leading) {
      Text(title).font(.subheadline)
      Text(value)
    }
  }
}

struct ExampleLiveSessionError: Error, CustomNSError {
  public var errorUserInfo: [String: Any] {
    [
      NSLocalizedDescriptionKey: "The live session lost connection to the server."
    ]
  }
}

#Preview("Live error") {
  LiveErrorDetailsView(error: ExampleLiveSessionError())
}
