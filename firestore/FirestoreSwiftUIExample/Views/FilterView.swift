//
//  FilterView.swift
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

struct FilterView: View {
  var viewModel: RestaurantListViewModel
  @Binding var showFilterView: Bool
  @Binding var selectedCategory: String?
  @Binding var selectedCity: String?
  @Binding var selectedPrice: Int?
  @Binding var selectedSortOption: String?

  var body: some View {
    NavigationView {
      Form {
        Section {
          Picker("Category", selection: $selectedCategory) {
            Text("None").tag(nil as String?)
            ForEach(Restaurant.categories, id: \.self) { category in
              Text(category).tag(category as String?)
            }
          }
        }
        Section {
          Picker("City", selection: $selectedCity) {
            Text("None").tag(nil as String?)
            ForEach(Restaurant.cities, id: \.self) { city in
              Text(city).tag(city as String?)
            }
          }
        }
        Section {
          Picker("Price", selection: $selectedPrice) {
            Text("None").tag(nil as Int?)
            ForEach(Restaurant.prices, id: \.self) { price in
              Text(Restaurant.priceString(from: price)).tag(price as Int?)
            }
          }
        }
        Section {
          Picker("Sort By", selection: $selectedSortOption) {
            Text("None").tag(nil as String?)
            ForEach(Restaurant.sortOptions, id: \.self) { option in
              Text(option).tag(option as String?)
            }
          }
        }
        Button("Clear Filters", action: {
          selectedCategory = nil
          selectedCity = nil
          selectedPrice = nil
          selectedSortOption = nil
        })
      }
      .navigationBarTitle("Filter", displayMode: .inline)
      .navigationBarItems(trailing: Button("Done", action: { filter() }))
    }
  }

  func filter() {
    let query = viewModel.query(category: selectedCategory, city: selectedCity,
                                price: selectedPrice, sortOption: selectedSortOption)
    viewModel.filter(query: query)

    showFilterView = false
  }
}
