//
//  RestaurantView.swift
//  FirestoreSwiftUIExample
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
