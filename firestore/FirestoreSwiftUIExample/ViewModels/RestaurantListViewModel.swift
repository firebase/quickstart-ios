//
//  RestaurantListViewModel.swift
//  FirestoreSwiftUIExample
//
//  Created by Rachel Collins on 3/2/21.
//  Copyright © 2021 Firebase. All rights reserved.
//

import Combine
import Firebase

class RestaurantListViewModel: ObservableObject {

    @Published var restaurants: [Restaurant] = []
    private var db = Firestore.firestore()

    func fetchData() {
        db.collection("restaurants").addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error getting restaurants: \(error.localizedDescription)")
                return
            }

            self.restaurants = querySnapshot?.documents.compactMap { document in
                try? document.data(as: Restaurant.self)
            } ?? []
        }
    }
}
