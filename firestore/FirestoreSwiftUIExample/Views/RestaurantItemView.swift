//
//  RestaurantView.swift
//  FirestoreSwiftUIExample
//

import SwiftUI
import SDWebImageSwiftUI

struct RestaurantItemView: View {
    var restaurant: Restaurant

    var body: some View {
        HStack {
            ImageThumbnail(imageURL: restaurant.photo)
            VStack(alignment: .leading) {
                HStack {
                    Text(restaurant.name)
                        .frame(alignment: .leading)
                    Spacer()
                    Price(price: restaurant.price)
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
        let data = Restaurant(id: .init(), name: "Pizza Place", category: "Pizza", city: "Austin", price: 2, ratingCount: 1, averageRating: 4, photo: Restaurant.imageURL(forName: "Place Place"))
        RestaurantItemView(restaurant: data)
    }
}

struct ImageThumbnail: View {
    var imageURL: URL

    var body: some View {
        WebImage(url: imageURL)
            .resizable()
            .placeholder(Image(systemName: "photo"))
            .aspectRatio(1, contentMode: .fill)
            .frame(width: 100, height: 100, alignment: .leading)
    }
}

struct Price: View {
    var price: Int

    var body: some View {
        Text(priceString(from: price))
            .font(.footnote)
            .foregroundColor(Color.gray)
            .multilineTextAlignment(.trailing)
    }

    func priceString(from price: Int) -> String {
      let priceText: String
      switch price {
          case 1:
              priceText = "$"
          case 2:
              priceText = "$$"
          case 3:
              priceText = "$$$"
          case _:
              fatalError("price must be between one and three")
      }

      return priceText
    }
}
