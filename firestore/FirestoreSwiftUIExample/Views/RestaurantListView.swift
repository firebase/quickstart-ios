//
//  RestaurantListView.swift
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
import FirebaseFirestore

struct RestaurantListView: View {
  @ObservedObject var restaurantListViewModel = RestaurantListViewModel()
  @State var showFilterView = false
  @State var selectedCategory: String? = nil
  @State var selectedCity: String? = nil
  @State var selectedPrice: Int? = nil
  @State var selectedSortOption: String? = nil

  var body: some View {
    NavigationView {
      VStack {
        List(restaurantListViewModel.restaurants) { restaurant in
          RestaurantItemView(restaurant: restaurant)
        }
      }
      .sheet(isPresented: $showFilterView) {
        FilterView(viewModel: self.restaurantListViewModel, showFilterView: self.$showFilterView,
                   selectedCategory: self.$selectedCategory, selectedCity: self.$selectedCity,
                   selectedPrice: self.$selectedPrice, selectedSortOption: self.$selectedSortOption)
      }
      .navigationBarTitle("Friendly Eats")
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Populate") {
            restaurantListViewModel.populate()
          }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button(getFilterText()) {
            self.showFilterView = true
          }
        }
      }
      .onAppear {
        let query = restaurantListViewModel.query(category: selectedCategory, city: selectedCity,
                                                  price: selectedPrice,
                                                  sortOption: selectedSortOption)
        restaurantListViewModel.subscribe(to: query)
      }
      .onDisappear {
        restaurantListViewModel.unsubscribe()
      }
    }
  }

  func getFilterText() -> String {
    var numFiltersApplied = 0

    if selectedCategory != nil {
      numFiltersApplied += 1
    }
    if selectedCity != nil {
      numFiltersApplied += 1
    }
    if selectedPrice != nil {
      numFiltersApplied += 1
    }

    if numFiltersApplied == 0 {
      return "Filter"
    } else {
      return "Filters (\(numFiltersApplied))"
    }
  }
}

struct RestaurantListView_Previews: PreviewProvider {
  static var previews: some View {
    RestaurantListView(restaurantListViewModel: RestaurantListViewModel())
  }
}
