//
//  RestaurantView.swift
//  FirestoreSwiftUIExample
//
//  Created by Rachel Collins on 2/26/21.
//  Copyright © 2021 Firebase. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct RestaurantItemView: View {
    var restaurant: Restaurant

    var body: some View {
        HStack {
            WebImage(url: restaurant.photo)
                .resizable()
                .placeholder(Image(systemName: "photo"))
                .aspectRatio(1, contentMode: .fill)
                .frame(width: 100, height: 100, alignment: .leading)
            VStack(alignment: .leading) {
                Text(restaurant.name)
                Text("Star Placeholder")
                Spacer()
                HStack {
                    Text(restaurant.category)
                    Text("•")
                    Text(restaurant.city)
                }
            }
            Spacer()
            Text("$$$")
        }
        .padding([.bottom, .trailing])
    }
}

struct RestaurantItemView_Previews: PreviewProvider {
    static var previews: some View {
        let data = Restaurant(id: .init(), name: "Pizza Place", category: "Pizza", city: "Austin", price: 0, ratingCount: 0, averageRating: 0, photo: Restaurant.imageURL(forName: "Place Place"))
        RestaurantItemView(restaurant: data)
    }
}
