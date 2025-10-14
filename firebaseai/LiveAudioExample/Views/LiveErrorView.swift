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
import SwiftUI

struct LiveErrorView: View {
  var error: Error
  @State private var isDetailsSheetPresented = false

  var body: some View {
    HStack {
      Text("An error occurred.")
      Button(action: { isDetailsSheetPresented.toggle() }) {
        Image(systemName: "info.circle")
      }.foregroundStyle(.red)
    }
    .frame(maxWidth: .infinity, alignment: .center)
    .listRowSeparator(.hidden)
    .sheet(isPresented: $isDetailsSheetPresented) {
      LiveErrorDetailsView(error: error)
    }
  }
}

#Preview {
  let cause = NSError(domain: "network.api", code: 1, userInfo: [
    NSLocalizedDescriptionKey: "Network timed out.",
  ])
  let error = LiveSessionLostConnectionError(underlyingError: cause)

  LiveErrorView(error: error)
}
