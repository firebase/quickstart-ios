//
//  RestaurantViewModel.swift
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

import Firebase
import Combine

class RestaurantViewModel: ObservableObject {
  var restaurant: Restaurant

  @Published var reviews = [Review]()
  private var db = Firestore.firestore()
  private var listener: ListenerRegistration?

  init(restaurant: Restaurant) {
    self.restaurant = restaurant
  }

  deinit {
    unsubscribe()
  }

  func add(review: Review) {
    db.runTransaction({ (transaction, errorPointer) -> Any? in
      let restaurantRef = self.restaurant.reference!
      let restaurantDocument: DocumentSnapshot
      do {
        try restaurantDocument = transaction.getDocument(restaurantRef)
      } catch let fetchError as NSError {
        errorPointer?.pointee = fetchError
        return nil
      }

      guard let ratingCount = restaurantDocument.data()?["numRatings"] as? Int else {
        errorPointer?.pointee = self.getNSError(document: restaurantDocument)
        return nil
      }

      guard let averageRating = restaurantDocument.data()?["avgRating"] as? Float else {
        errorPointer?.pointee = self.getNSError(document: restaurantDocument)
        return nil
      }

      let newAverage = (Float(ratingCount) * averageRating + Float(review.rating))
        / Float(ratingCount + 1)

      transaction.setData([
        "numRatings": ratingCount + 1,
        "avgRating": newAverage,
      ], forDocument: restaurantRef, merge: true)

      let reviewDocument = self.restaurant.ratingsCollection!.document()
      do {
        _ = try transaction.setData(from: review, forDocument: reviewDocument)
      } catch {
        fatalError("Unable to add review: \(error.localizedDescription).")
      }

      return nil
    }) { object, error in
      if let error = error {
        print("Transaction failed: \(error)")
      }
    }
  }

  func unsubscribe() {
    if listener != nil {
      listener?.remove()
      listener = nil
    }
  }

  func subscribe() {
    if listener == nil {
      listener = restaurant.ratingsCollection?.addSnapshotListener {
        [weak self] querySnapshot, error in
        guard let documents = querySnapshot?.documents else {
          print("Error fetching documents: \(error!)")
          return
        }

        guard let self = self else { return }
        self.reviews = documents.compactMap { document in
          do {
            return try document.data(as: Review.self)
          } catch {
            print(error)
            return nil
          }
        }
      }
    }
  }

  func getNSError(document: DocumentSnapshot) -> NSError {
    return NSError(
      domain: "AppErrorDomain",
      code: -1,
      userInfo: [
        NSLocalizedDescriptionKey: "Unable to retrieve value from snapshot \(document)",
      ]
    )
  }
}
