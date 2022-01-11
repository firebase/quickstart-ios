//
//  AddMessage.swift
//  FunctionsExample
//
//  Created by Gran Luo on 11/16/21.
//

import SwiftUI
import Firebase

struct AddMessage: View {
  @State private var comment: String = ""
  @State private var outcome: String = ""
  private var functions = Functions.functions()
  var body: some View {
    
    ZStack{
      BackgroundFrame()
      VStack{
        VStack{
          Text("Add your message")
          #if os(macOS)
          TextField("", text: $comment)
          #else
          TextField("", text: $comment)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray5)))
            .frame(width: ScreenDimensions.width * 0.8)
          #endif
          Text(outcome)
        }
        Button(action: {didTapAddMessage()} ){
          Text("Add Message")
            .padding()
            .foregroundColor(.white)
            .background(Color("Amber400"))
        }

      }
    }
  }

  func didTapAddMessage(){

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

        print( text)
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

struct CommentCell {

}
