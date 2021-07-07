//
//  StarsView.swift
//  FirestoreSwiftUIExample
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

struct StarsView: View {
  var rating: Int
  var color: Color
  var outlineColor: Color

  var body: some View {
    HStack {
      ForEach(1 ... 5, id: \.self) { i in
        getStar(num: i, rating: rating)
          .frame(width: 12, height: 20)
          .foregroundColor(getStarColor(num: i, rating: rating))
      }
    }
  }

  func getStar(num: Int, rating: Int) -> Image {
    num > rating ? Image(systemName: "star") : Image(systemName: "star.fill")
  }

  func getStarColor(num: Int, rating: Int) -> Color {
    return num > rating ? outlineColor : color
  }
}

struct StarsInputView: View {
  @EnvironmentObject var newReview: NewReview

  var body: some View {
    HStack {
      ForEach(1 ... 5, id: \.self) { i in
        getStar(num: i)
          .resizable()
          .frame(width: 50.0, height: 50.0)
          .foregroundColor(newReview.rating == 0 ? Color.gray : Color.yellow)
          .onTapGesture { newReview.rating = i }
      }
    }
  }

  func getStar(num: Int) -> Image {
    if newReview.rating == 0 {
      return Image(systemName: "star")
    } else {
      return num > newReview.rating ? Image(systemName: "star") : Image(systemName: "star.fill")
    }
  }
}

struct StarsView_Previews: PreviewProvider {
  static var previews: some View {
    StarsView(rating: 3, color: Color.purple, outlineColor: Color.black)
    StarsInputView()
  }
}
