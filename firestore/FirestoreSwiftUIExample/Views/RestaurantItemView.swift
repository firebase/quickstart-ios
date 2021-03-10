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
    HStack {
      ImageThumbnailView(imageURL: restaurant.photo)
      VStack(alignment: .leading) {
        HStack {
          Text(restaurant.name)
            .frame(alignment: .leading)
          Spacer()
          PriceView(price: restaurant.price)
        }
        StarsView(rating: Int(restaurant.averageRating.rounded()))
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

struct RestaurantItemView_Previews: PreviewProvider {
  static var previews: some View {
    let data = Restaurant(id: .init(), name: "Pizza Place", category: "Pizza", city: "Austin", price: 2, ratingCount: 1, averageRating: 4, photo: Restaurant.imageURL(forName: "Pizza Place"))
    RestaurantItemView(restaurant: data)
  }
}
