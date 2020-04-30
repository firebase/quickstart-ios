//
//  Copyright (c) 2020 Google LLC
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

import UIKit
import Firebase

class ShowAllViewController: UITableViewController {

  var restaurants: LocalCollection<Restaurant>?
  var reviewCollections: [LocalCollection<Review>] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    let query = Firestore.firestore().collection("restaurants")
    restaurants = LocalCollection(query: query) { [weak self] _ in
      guard let self = self else { return }
      guard let restaurants = self.restaurants else { return }
      self.tableView.reloadData()
      func buildQuery(for restaurant: DocumentSnapshot) -> Query {
        return Firestore.firestore().collection("restaurants/\(restaurant.documentID)/ratings")
      }

      self.reviewCollections.forEach { $0.stopListening() }
      guard let tableView = self.tableView else { return }

      let reviews = restaurants.documents.indices.map { (index) -> LocalCollection<Review> in
        let reviewQuery = buildQuery(for: restaurants.documents[index])
        let section = Int(index)
        return LocalCollection<Review>(query: reviewQuery) { _ in
          tableView.reloadSections([section], with: .automatic)
        }
      }

      reviews.forEach { $0.listen() }
      self.reviewCollections = reviews
    }

    tableView.register(UITableViewCell.self,
                       forCellReuseIdentifier: "CondensedReviewCell")
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    restaurants?.listen()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    restaurants?.stopListening()
  }

  // MARK: - UITableViewDataSource

  override func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "CondensedReviewCell",
                                             for: indexPath)
    let reviews = reviewCollections[indexPath.section]
    let review = reviews[indexPath.row]
    cell.textLabel?.text = review.text
    return cell
  }

  override func tableView(_ tableView: UITableView,
                          titleForHeaderInSection section: Int) -> String? {
    guard let restaurants = restaurants else {
      fatalError("view should be empty if no items are present")
    }
    return restaurants[section].name
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    guard let restaurants = restaurants else { return 0 }
    return restaurants.count
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard reviewCollections.count > section else { return 0 }
    return reviewCollections[section].count
  }

}
