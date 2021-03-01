//
//  ContentView.swift
//  FirestoreSwiftUIExample
//
//  Created by Rachel Collins on 2/26/21.
//  Copyright © 2021 Firebase. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List(/*@START_MENU_TOKEN@*/0 ..< 5/*@END_MENU_TOKEN@*/) { item in
                NavigationLink(destination: RestaurantDetailView()) {
                    RestaurantItemView()
                }
            }
            .navigationBarTitle("Friendly Eats", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Populate") {
                        print("populating")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Filter") {
                        print("filtering")
                    }
                }
            }
        }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct RestaurantDetailView: View {
    var body: some View {
        Text("Detail View Placeholder")
    }
}
