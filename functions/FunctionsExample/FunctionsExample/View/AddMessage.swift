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
import Firebase

struct AddMessage: View {
  @State private var comment: String = ""
  @State private var outcome: String = ""
  private var functions = Functions.functions()
  var body: some View {
    ZStack {
      BackgroundFrame()
      VStack {
        VStack {
          Text("Add your message")
          TextField("", text: $comment)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray5)))
            .frame(width: ScreenDimensions.width * 0.8)
          Text(outcome)
        }
        Button(action: { didTapAddMessage() }) {
          Text("Add Message")
            .padding()
            .foregroundColor(.white)
            .background(Color("Amber400"))
        }
      }
      .padding()
    }
  }

  func didTapAddMessage() {
    // [START function_add_message]
    functions.httpsCallable("addMessage").call(["text": $comment.wrappedValue]) { result, error in
      // [START function_error]
      if let error = error as NSError? {
        if error.domain == FunctionsErrorDomain {
          let code = FunctionsErrorCode(rawValue: error.code)
          let message = error.localizedDescription
          let details = error.userInfo[FunctionsErrorDetailsKey]
        }
        // [START_EXCLUDE]
        print(error)
        return
          // [END_EXCLUDE]
      }
      // [END function_error]
      if let data = result?.data as? [String: Any], let text = data["text"] as? String {
        print(text)
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
