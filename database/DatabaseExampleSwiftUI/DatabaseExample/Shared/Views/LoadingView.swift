//
//  Copyright (c) 2021 Google Inc.
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

struct LoadingView: View {
  @State var animating = false
  var body: some View {
    VStack {
      Circle()
        .trim(from: 0, to: 0.7)
        .stroke(Color(.systemTeal), lineWidth: 8)
        .frame(width: 75, height: 75)
        .rotationEffect(.init(degrees: animating ? 360 : 0))
        .padding()
    }
    .background(Color.white)
    .cornerRadius(20)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black.opacity(0.4).ignoresSafeArea(.all, edges: .all))
    .onAppear(perform: {
      withAnimation(Animation.linear(duration: 1)) {
        animating.toggle()
      }
    })
  }
}

struct LoadingView_Previews: PreviewProvider {
  static var previews: some View {
    LoadingView()
  }
}
