//
//  Copyright (c) 2016 Google Inc.
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
import FirebaseFirestoreSwift

struct Restaurant: Codable {
  var name: String
  var category: String // Could become an enum
  var city: String
  var price: Int // from 1-3; could also be an enum
  var ratingCount: Int // numRatings
  var averageRating: Float
  var photo: URL

  enum CodingKeys: String, CodingKey {
    case name
    case category
    case city
    case price
    case ratingCount = "numRatings"
    case averageRating = "avgRating"
    case photo
  }
}

extension Restaurant {
  static let cities = [
    "Albuquerque",
    "Arlington",
    "Atlanta",
    "Austin",
    "Baltimore",
    "Boston",
    "Charlotte",
    "Chicago",
    "Cleveland",
    "Colorado Springs",
    "Columbus",
    "Dallas",
    "Denver",
    "Detroit",
    "El Paso",
    "Fort Worth",
    "Fresno",
    "Houston",
    "Indianapolis",
    "Jacksonville",
    "Kansas City",
    "Las Vegas",
    "Long Beach",
    "Los Angeles",
    "Louisville",
    "Memphis",
    "Mesa",
    "Miami",
    "Milwaukee",
    "Nashville",
    "New York",
    "Oakland",
    "Oklahoma",
    "Omaha",
    "Philadelphia",
    "Phoenix",
    "Portland",
    "Raleigh",
    "Sacramento",
    "San Antonio",
    "San Diego",
    "San Francisco",
    "San Jose",
    "Tucson",
    "Tulsa",
    "Virginia Beach",
    "Washington",
  ]

  static let categories = [
    "Brunch", "Burgers", "Coffee", "Deli", "Dim Sum", "Indian", "Italian",
    "Mediterranean", "Mexican", "Pizza", "Ramen", "Sushi",
  ]

  static func imageURL(forName name: String) -> URL {
    let number = (abs(name.hashValue) % 22) + 1
    let URLString =
      "https://storage.googleapis.com/firestorequickstarts.appspot.com/food_\(number).png"
    return URL(string: URLString)!
  }

  var imageURL: URL {
    return Restaurant.imageURL(forName: name)
  }
}

struct Review: Codable {
  var rating: Int // Can also be enum
  var userID: String
  var username: String
  var text: String
  var date: Timestamp

  enum CodingKeys: String, CodingKey {
    case rating
    case userID = "userId"
    case username = "userName"
    case text
    case date
  }
}
