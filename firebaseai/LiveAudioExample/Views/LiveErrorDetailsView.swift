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

@testable import FirebaseAI
import MarkdownUI
import SwiftUI

struct LiveErrorDetailsView: View {
  var error: Error

  var body: some View {
    NavigationView {
      Form {
        if let title = error.title {
          Section("Error type") {
            Text(title)
          }
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

private extension Error {
  var title: String? {
    switch self {
    case _ as LiveSessionSetupError:
      "Failed to set up live session"
    case _ as LiveSessionLostConnectionError:
      "Lost connection to the model"
    case _ as LiveSessionUnexpectedClosureError:
      "Session was closed"
    case _ as LiveSessionUnsupportedMessageError:
      "Unsupported model message"
    default:
      nil
    }
  }
}

#Preview("Live error") {
  let cause = NSError(domain: "network.api", code: 1, userInfo: [
    NSLocalizedDescriptionKey: "Network timed out."
  ])
  let error = LiveSessionLostConnectionError(underlyingError: cause)

  LiveErrorDetailsView(error: error)
}

#Preview("Unexpected error") {
  let error = NSError(domain: "network.api", code: 1, userInfo: [
    NSLocalizedDescriptionKey: "Network timed out."
  ])

  LiveErrorDetailsView(error: error)
}
