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

struct AddNumbersView: View {
  @State private var num1: String = ""
  @State private var num2: String = ""
  @State private var outcome: String = ""
  let textForegroundColor = ColorConstants.textForegroundColor
  let roundRectangleFillColor = ColorConstants.roundRectangleFillColor
  private var functions = Functions.functions()
  var body: some View {
    BackgroundFrame(
      title: "AddNumbers",
      description: "Add two integers and output the sum.",
      buttonAction: didTapCalculate
    ) {
      VStack {
        HStack {
          Spacer()
          TextField("", text: $num1, prompt: Text("Num1"))
            .multilineTextAlignment(.center)
            .background(RoundedRectangle(cornerRadius: 16).fill(roundRectangleFillColor))
            .padding()

          #if os(iOS)
            .keyboardType(.numberPad)
          #endif
          Image(systemName: "plus")
          TextField("", text: $num2, prompt: Text("Num2"))
            .multilineTextAlignment(.center)
            .background(RoundedRectangle(cornerRadius: 16).fill(roundRectangleFillColor))
            .padding()
          #if os(iOS)
            .keyboardType(.numberPad)
          #endif
          Spacer()
        }
        VStack {
          Text(outcome)
        }
      }
    }
  }

  func didTapCalculate() {
    Task {
      do {
        let function = functions.httpsCallable(
          "addNumbers",
          requestAs: [String: String].self,
          responseAs: [String: Int].self
        )
        let result = try await function.call([
          "firstNumber": $num1.wrappedValue,
          "secondNumber": $num2.wrappedValue,
        ])
        if let operationResult = result["operationResult"] {
          self.outcome = String(operationResult)
        } else {
          self.outcome = "The return result is invalid."
        }
      } catch {
        print(error)
      }
    }
  }
}

struct AddNumbers_Previews: PreviewProvider {
  static var previews: some View {
    AddNumbersView()
  }
}
