//
//  ContentView.swift
//  FirestoreSwiftUIExample
//

import SwiftUI
import Firebase

struct ContentView: View {
  let db = Firestore.firestore()
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
        self.restaurantListViewModel.fetchData()
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Populate") {
            populate()
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

      let collection = db.collection("restaurants")

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

      let batch = db.batch()
      //TODO: guard let user = Auth.auth().currentUser else { continue }
      var average: Float = 0
      for _ in 0 ..< 10 {
        let rating = Int(arc4random_uniform(5) + 1)
        average += Float(rating) / 10
        let text = rating > 3 ? "good" : "food was too spicy"

        //TODO: userID: user.uid,
        //TODO: username: user.displayName ?? "Anonymous",
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
      batch.commit(completion: { (error) in
        guard let error = error else { return }
        print("Error generating reviews: \(error). Check your Firestore permissions.")
      })
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
