//
//  Copyright 2022 Google LLC
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
import FirebaseFunctionsSwift

struct CapitalizeMessageView: View {
  @State private var comment: String = ""
  @State private var outcome: String = ""

  let roundRectangleFillColor = ColorConstants.roundRectangleFillColor
  private var functions = Functions.functions()
  var body: some View {
    BackgroundFrame(
      title: "CapitalizeMessage",
      description: "Capitalize the input message and return it.",
      buttonAction: didTapAddMessage
    ) {
      VStack {
        TextField("", text: $comment, prompt: Text("Type message"))
          .background(RoundedRectangle(cornerRadius: 16).fill(roundRectangleFillColor))
          .padding()
        Text(outcome)
      }
      .padding()
    }
  }

  func didTapAddMessage() {
    Task {
      do {
        let function = functions.httpsCallable(
          "capitalizeMessage",
          requestAs: [String: String].self,
          responseAs: [String: String].self
        )
        let result = try await function.call(["text": $comment.wrappedValue])
        if let text = result["text"] {
          self.outcome = text
        }
      } catch {
        print(error)
      }
    }
  }
}

struct AddMessage_Previews: PreviewProvider {
  static var previews: some View {
    CapitalizeMessageView()
  }
}
