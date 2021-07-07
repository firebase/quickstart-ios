//
//  RestaurantDetailView.swift
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
import SDWebImageSwiftUI

struct RestaurantDetailView: View {
  var restaurant: Restaurant
  @ObservedObject var viewModel: RestaurantViewModel
  @State var showAddReviewView = false

  init(restaurant: Restaurant) {
    self.restaurant = restaurant
    viewModel = RestaurantViewModel(restaurant: restaurant)
  }

  var body: some View {
    let restaurant = viewModel.restaurant

    VStack {
      RestaurantHeaderView(restaurant: restaurant)
      List(viewModel.reviews) { review in
        ReviewView(review: review)
      }
    }
    .sheet(isPresented: $showAddReviewView) {
      WriteReviewView(restaurant: restaurant, showAddReviewView: self.$showAddReviewView)
    }
    .navigationBarTitle(restaurant.name, displayMode: .inline)
    .toolbar {
      Button("Add") {
        self.showAddReviewView = true
      }
    }
    .onAppear {
      viewModel.subscribe()
    }
    .onDisappear {
      viewModel.unsubscribe()
    }
  }
}

struct TransparentRectangleView: View {
  var body: some View {
    Rectangle()
      .foregroundColor(Color.black)
      .opacity(0.4)
  }
}

struct RestaurantDetailView_Previews: PreviewProvider {
  static var previews: some View {
    let restaurant = Restaurant(name: "Pizza Place", category: "Pizza", city: "Austin", price: 2,
                                ratingCount: 1, averageRating: 4,
                                photo: Restaurant.imageURL(forName: "Pizza Place"))
    RestaurantDetailView(restaurant: restaurant)
  }
}
