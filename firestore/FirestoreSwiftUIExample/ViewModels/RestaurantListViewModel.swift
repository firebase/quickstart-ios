//
//  RestaurantListViewModel.swift
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

import Combine
import Firebase

class RestaurantListViewModel: ObservableObject {
  @Published var restaurants = [Restaurant]()
  private var db = Firestore.firestore()
  private var listener: ListenerRegistration?

  deinit {
    unsubscribe()
  }

  func unsubscribe() {
    if listener != nil {
      listener?.remove()
      listener = nil
    }
  }

  func subscribe() {
    if listener == nil {
      listener = db.collection("restaurants").addSnapshotListener { [weak self] (querySnapshot, error) in
        guard let documents = querySnapshot?.documents else {
          print("Error fetching documents: \(error!)")
          return
        }

        guard let self = self else { return }
        self.restaurants = documents.compactMap { document in
          do {
            return try document.data(as: Restaurant.self)
          } catch let error {
            print(error)
            return nil
          }
        }
      }
    }
  }

  func populate() {
    db.populate()
  }
}
