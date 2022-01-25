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
import Firebase

struct AddMessage: View {
  @State private var comment: String = ""
  @State private var outcome: String = ""
  private var functions = Functions.functions()
  var body: some View {
    ZStack {
      BackgroundFrame(
        title: "AddMessage",
        description: "Capitalize the input message and return it.",
        hitButton: didTapAddMessage
      ) {
        VStack {
          VStack {
            TextField("", text: $comment, prompt: Text("Type message"))
              .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray5)))
              .frame(width: ScreenDimensions.width * 0.8)
            Text(outcome)
          }
        }
        .padding()
      }
    }
  }

  func didTapAddMessage() {
    functions.httpsCallable("addMessage").call(["text": $comment.wrappedValue]) { result, error in
      if let error = error as NSError? {
        if error.domain == FunctionsErrorDomain {
          let code = FunctionsErrorCode(rawValue: error.code)
          let message = error.localizedDescription
          let details = error.userInfo[FunctionsErrorDetailsKey]
          self
            .outcome =
            "Error Code: \(code!)\nError Message: \(message)\nError Details: \(details ?? "null")"
        }
        print(error)
        return
      }
      if let data = result?.data as? [String: Any], let text = data["text"] as? String {
        self.outcome = text
      }
    }
  }
}

struct AddMessage_Previews: PreviewProvider {
  static var previews: some View {
    AddMessage()
  }
}

struct CommentCell {}
