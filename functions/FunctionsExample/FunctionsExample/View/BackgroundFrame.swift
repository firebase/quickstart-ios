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

struct BackgroundFrame: View {
  var body: some View {
    RoundedRectangle(cornerRadius: 25)
      .fill(Color.white)
      .frame(width: ScreenDimensions.width * 0.95, height: 200)
      .shadow(color: Color(.black), radius: 5, x: 3, y: 1)
  }
}

struct BackgroundFrame_Previews: PreviewProvider {
  static var previews: some View {
    BackgroundFrame()
  }
}

class ScreenDimensions {
  static var width: CGFloat = UIScreen.main.bounds.size.width
  static var height: CGFloat = UIScreen.main.bounds.size.height
}
