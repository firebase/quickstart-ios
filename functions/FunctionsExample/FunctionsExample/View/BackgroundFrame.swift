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

struct BackgroundFrame<Content: View>: View {
  var title: String
  var description: String
  let content: Content
  let buttonAction: () -> Void
  init(title: String, description: String, buttonAction: @escaping () -> Void,
       @ViewBuilder content: () -> Content) {
    self.title = title
    self.description = description
    self.content = content()
    self.buttonAction = buttonAction
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text(title)
        .fontWeight(.bold)
        .font(.title3)
      Text(description)
        .font(.subheadline)
        .foregroundColor(Color(UIColor.secondaryLabel))
      ZStack {
        RoundedRectangle(cornerRadius: 16)
          .fill(Color(.secondarySystemBackground))
          .frame(height: 150)
        content
      }
      CustomStyledButton(title: "Run", action: buttonAction)
    }
    .padding()
  }
}

struct BackgroundFrame_Previews: PreviewProvider {
  static var previews: some View {
    BackgroundFrame(
      title: "Function",
      description: "Function description",
      buttonAction: { print("button") }
    ) {
      Text("Testing View")
    }
  }
}

struct CustomStyledButton: View {
  let title: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      /// Embed in an HStack to display a wide button with centered text.
      HStack {
        Spacer()
        Text(title)
          .padding()
          .accentColor(.white)
        Spacer()
      }
    }
    .background(Color.orange)
    .cornerRadius(16.0)
  }
}
