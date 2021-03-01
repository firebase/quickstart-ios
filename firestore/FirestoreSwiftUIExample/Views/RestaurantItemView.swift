//
//  RestaurantView.swift
//  FirestoreSwiftUIExample
//
//  Created by Rachel Collins on 2/26/21.
//  Copyright © 2021 Firebase. All rights reserved.
//

import SwiftUI

struct RestaurantItemView: View {
    var body: some View {
        HStack {
            Image(systemName: "circle")
            VStack(alignment: .leading) {
                Text("Restaurant Name")
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
        RestaurantItemView()
    }
}
