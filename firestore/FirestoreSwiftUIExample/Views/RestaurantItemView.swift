//
//  RestaurantView.swift
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

struct RestaurantItemView: View {
  var restaurant: Restaurant

  var body: some View {
    NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
      HStack {
        RestaurantImageView(imageURL: restaurant.photo, isThumbnail: true)
        VStack(alignment: .leading) {
          HStack {
            Text(restaurant.name)
              .frame(alignment: .leading)
            Spacer()
            PriceView(price: restaurant.price, color: Color.gray)
          }
          StarsView(
            rating: Int(restaurant.averageRating.rounded()),
            color: Color.yellow,
            outlineColor: Color.gray
          )
          Spacer()
          HStack {
            Text(restaurant.category)
            Text("•")
            Text(restaurant.city)
          }
          .foregroundColor(Color.gray)
          .font(.footnote)
        }
      }
      .padding([.bottom, .trailing])
    }
  }
}

struct RestaurantItemView_Previews: PreviewProvider {
  static var previews: some View {
    let restaurant = Restaurant(name: "Pizza Place", category: "Pizza", city: "Austin", price: 2,
                                ratingCount: 1, averageRating: 4,
                                photo: Restaurant.imageURL(forName: "Pizza Place"))
    RestaurantItemView(restaurant: restaurant)
  }
}
