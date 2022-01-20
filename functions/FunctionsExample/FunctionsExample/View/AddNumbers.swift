//
//  AddNumbers.swift
//  FunctionsExample
//
//  Created by Gran Luo on 1/12/22.
//

import SwiftUI
import Firebase

struct AddNumbers: View {
  @State private var num1: String = ""
  @State private var num2: String = ""
  @State private var outcome: String = ""
  private var functions = Functions.functions()
  var body: some View {
    ZStack {
      BackgroundFrame()
      VStack {
        HStack {
          Spacer()
          VStack {
            Text("Num1")
            #if os(macOS)
              TextField("", text: $num1).multilineTextAlignment(.center)
            #else
              TextField("", text: $num1).multilineTextAlignment(.center)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray5)))
                .frame(width: ScreenDimensions.width * 0.2)
                .keyboardType(.decimalPad)
            #endif
          }
          Spacer()
          Text("+")
          Spacer()
          VStack {
            Text("Num2")
            TextField("", text: $num2).multilineTextAlignment(.center)
              .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray5)))
              .frame(width: ScreenDimensions.width * 0.2)
              .keyboardType(.decimalPad)
          }
          Spacer()
        }
        HStack {
          Button(action: {
            didTapCalculate()
          }) {
            Text("Calculate")
              .padding()
              .foregroundColor(.white)
              .background(Color("Amber400"))
          }
          Text("\(outcome)")
        }
      }
    }
  }

  func didTapCalculate() {
    // [START function_add_message]
    functions.httpsCallable("addNumbers")
      .call(["firstNumber": $num1.wrappedValue,
             "secondNumber": $num2.wrappedValue]) { result, error in

        // [START function_error]
        if let error = error as NSError? {
          if error.domain == FunctionsErrorDomain {
            let code = FunctionsErrorCode(rawValue: error.code)
            let message = error.localizedDescription
            let details = error.userInfo[FunctionsErrorDetailsKey]
            print("Error Code: \(code!)")
            print("Error Message: \(message)")
            print("Error Details: \(details!)")
          }
          // [START_EXCLUDE]
          print(error)

          return
            // [END_EXCLUDE]
        }

        // [END function_error]
        print("The result is \(result?.data ?? "null")...")

        if let operationResult = (result?.data as? [String: Any])?["operationResult"] as? Int {
          self.outcome = String(operationResult)
        }
      }
  }
}

struct AddNumbers_Previews: PreviewProvider {
  static var previews: some View {
    AddNumbers()
  }
}
