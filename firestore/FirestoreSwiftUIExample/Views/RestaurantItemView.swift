//
//  RestaurantView.swift
//  FirestoreSwiftUIExample
//
//  Created by Rachel Collins on 2/26/21.
//  Copyright © 2021 Firebase. All rights reserved.
//

import SwiftUI

struct RestaurantItemView: View {
    var restaurant: Restaurant

    var body: some View {
        HStack {
            Image(systemName: "circle")
            VStack(alignment: .leading) {
                Text(restaurant.name)
                Text("Star Placeholder")
                Spacer()
                Text("Type and location")
            }
            Spacer()
            Text("$$$")
        }
        .padding([.leading, .bottom, .trailing])
    }
}

struct RestaurantItemView_Previews: PreviewProvider {
    static var previews: some View {
        let data = Restaurant(id: .init(), name: "test123", category: "test123", city: "test123", price: 0, ratingCount: 0, averageRating: 0, photo: Restaurant.imageURL(forName: "test"))
        RestaurantItemView(restaurant: data)
    }
}
