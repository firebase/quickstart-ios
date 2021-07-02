//
//  Firestore+Extension.swift
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

extension Firestore {
  func populate() {
    let words = ["Bar", "Fire", "Grill", "Drive Thru", "Place", "Best", "Spot", "Prime", "Eatin'"]

    let cities = Restaurant.cities
    let categories = Restaurant.categories

    for _ in 0 ..< 20 {
      let randomIndexes = (Int(arc4random_uniform(UInt32(words.count))),
                           Int(arc4random_uniform(UInt32(words.count))))
      let name = words[randomIndexes.0] + " " + words[randomIndexes.1]
      let category = categories[Int(arc4random_uniform(UInt32(categories.count)))]
      let city = cities[Int(arc4random_uniform(UInt32(cities.count)))]
      let price = Int(arc4random_uniform(3)) + 1
      let photo = Restaurant.imageURL(forName: name)

      // Basic writes

      let collection = self.collection("restaurants")

      let restaurant = Restaurant(
        name: name,
        category: category,
        city: city,
        price: price,
        ratingCount: 10,
        averageRating: 0,
        photo: photo
      )

      let restaurantRef = collection.document()
      do {
        try restaurantRef.setData(from: restaurant)
      } catch {
        fatalError("Encoding Restaurant failed: \(error)")
      }

      let batch = self.batch()
      var average: Float = 0
      for _ in 0 ..< 10 {
        let rating = Int(arc4random_uniform(5) + 1)
        average += Float(rating) / 10
        let text = rating > 3 ? "good" : "food was too spicy"

        let review = Review(
          rating: rating,
          userID: "1234567890",
          username: "Anonymous",
          text: text,
          date: Timestamp()
        )

        let ratingRef = restaurantRef.collection("ratings").document()
        do {
          try batch.setData(from: review, forDocument: ratingRef)
        } catch {
          fatalError("Encoding Rating failed: \(error)")
        }
      }
      batch.updateData(["avgRating": average], forDocument: restaurantRef)
      batch.commit(completion: { error in
        guard let error = error else { return }
        print("Error generating reviews: \(error). Check your Firestore permissions.")
      })
    }
  }
}
