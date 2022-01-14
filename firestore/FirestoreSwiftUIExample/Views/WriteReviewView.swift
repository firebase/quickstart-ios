//
//  WriteReviewView.swift
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
import FirebaseAuth
import FirebaseFirestore

struct WriteReviewView: View {
  var restaurant: Restaurant
  @State private var text = Constants.placeholderText
  @StateObject var newReview = NewReview()
  @Binding var showAddReviewView: Bool

  var body: some View {
    VStack {
      StarsInputView()
      TextEditor(text: $text)
        .border(Color.gray)
        .onTapGesture { if text == Constants.placeholderText { text = "" } }
        .font(.body)
      Button("Add", action: {
        addReview()
        self.showAddReviewView = false
      })
        .disabled(newReview.rating == 0 || text == Constants.placeholderText || text.isEmpty)
        .padding()
        .font(.title2)
    }
    .padding()
    .environmentObject(newReview)
  }

  func addReview() {
    let review = Review(rating: newReview.rating,
                        userID: Auth.auth().currentUser?.uid ?? Constants.anonymous,
                        username: Auth.auth().currentUser?.displayName ?? Constants.anonymous,
                        text: text,
                        date: Timestamp())
    RestaurantViewModel(restaurant: restaurant).add(review: review)
  }
}

class NewReview: ObservableObject {
  @Published var rating = 0
}

private struct Constants {
  static let placeholderText = "Write a review..."
  static let anonymous = "Anonymous"
}
