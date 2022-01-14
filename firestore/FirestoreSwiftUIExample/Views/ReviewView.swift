//
//  ReviewView.swift
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
import FirebaseFirestore

struct ReviewView: View {
  var review: Review

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text(review.username)
          .fontWeight(.bold)
        Spacer()
        StarsView(rating: review.rating, color: Color.yellow, outlineColor: Color.gray)
      }
      Text(review.text)
    }
    .padding()
  }
}

struct ReviewView_Previews: PreviewProvider {
  static var previews: some View {
    let data = Review(rating: 3, userID: "1234", username: "userName",
                      text: "Great review!", date: Timestamp())
    ReviewView(review: data)
  }
}
