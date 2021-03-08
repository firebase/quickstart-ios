//
//  ContentView.swift
//  FirestoreSwiftUIExample
//

import SwiftUI
import Firebase

struct ContentView: View {
  @ObservedObject var restaurantListViewModel = RestaurantListViewModel()

  var body: some View {
    NavigationView {
      List(restaurantListViewModel.restaurants) { restaurant in
        NavigationLink(destination: RestaurantDetailView()) {
          RestaurantItemView(restaurant: restaurant)
        }
      }
      .navigationBarTitle("Friendly Eats", displayMode: .inline)
      .onAppear() {
        restaurantListViewModel.subscribe()
      }
      .onDisappear() {
        restaurantListViewModel.unsubscribe()
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Populate") {
            restaurantListViewModel.populate()
          }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Filter") {
            print(restaurantListViewModel.restaurants.count)
          }
        }
      }
    }
  }
}

struct RestaurantDetailView: View {
  var body: some View {
    Text("Detail View Placeholder")
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(restaurantListViewModel: RestaurantListViewModel())
  }
}
