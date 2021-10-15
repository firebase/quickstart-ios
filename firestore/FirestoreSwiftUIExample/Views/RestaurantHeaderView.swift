//
//  RestaurantHeaderView.swift
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

struct RestaurantHeaderView: View {
  var restaurant: Restaurant

  var body: some View {
    VStack {
      Spacer()
        .frame(height: 100)
      VStack(alignment: .leading) {
        HStack {
          Text(restaurant.name)
            .font(.title2)
            .bold()
            .frame(alignment: .leading)
          Spacer()
          PriceView(price: restaurant.price, color: Color.white)
        }
        StarsView(
          rating: Int(restaurant.averageRating.rounded()),
          color: Color.white,
          outlineColor: Color.white
        )
        HStack {
          Text(restaurant.category)
          Text("•")
          Text(restaurant.city)
        }
        .font(.subheadline)
      }
      .padding()
      .foregroundColor(Color.white)
      .background(TransparentRectangleView())
    }
    .background(RestaurantImageView(imageURL: restaurant.photo, isThumbnail: false))
  }
}

struct RestaurantHeaderView_Previews: PreviewProvider {
  static var previews: some View {
    let restaurant = Restaurant(name: "Pizza Place", category: "Pizza", city: "Austin", price: 2,
                                ratingCount: 1, averageRating: 4,
                                photo: Restaurant.imageURL(forName: "Pizza Place"))
    RestaurantHeaderView(restaurant: restaurant)
  }
}
