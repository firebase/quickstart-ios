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

import UIKit
import Firebase
import FirebaseFirestoreSwift
import FirebaseAuthUI
import FirebaseEmailAuthUI
import SDWebImage

func priceString(from price: Int) -> String {
  let priceText: String
  switch price {
  case 1:
    priceText = "$"
  case 2:
    priceText = "$$"
  case 3:
    priceText = "$$$"
  case _:
    fatalError("price must be between one and three")
  }

  return priceText
}

class RestaurantsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  @IBOutlet var tableView: UITableView!
  @IBOutlet var activeFiltersStackView: UIStackView!
  @IBOutlet var stackViewHeightConstraint: NSLayoutConstraint!

  @IBOutlet var cityFilterLabel: UILabel!
  @IBOutlet var categoryFilterLabel: UILabel!
  @IBOutlet var priceFilterLabel: UILabel!

  let backgroundView = UIImageView()

  private var restaurants: [Restaurant] = []
  private var documents: [DocumentSnapshot] = []

  fileprivate var query: Query? {
    didSet {
      if let listener = listener {
        listener.remove()
        observeQuery()
      }
    }
  }

  private var listener: ListenerRegistration?

  fileprivate func observeQuery() {
    guard let query = query else { return }
    stopObserving()

    // Display data from Firestore, part one

    listener = query.addSnapshotListener { [unowned self] snapshot, error in
      guard let snapshot = snapshot else {
        print("Error fetching snapshot results: \(error!)")
        return
      }
      let models = snapshot.documents.map { (document) -> Restaurant in
        let maybeModel: Restaurant?
        do {
          maybeModel = try document.data(as: Restaurant.self)
        } catch {
          fatalError(
            "Unable to initialize type \(Restaurant.self) with dictionary \(document.data()): \(error)"
          )
        }

        if let model = maybeModel {
          return model
        } else {
          // Don't use fatalError here in a real app.
          fatalError("Missing document of type \(Restaurant.self) at \(document.reference.path)")
        }
      }
      self.restaurants = models
      self.documents = snapshot.documents

      if self.documents.count > 0 {
        self.tableView.backgroundView = nil
      } else {
        self.tableView.backgroundView = self.backgroundView
      }

      self.tableView.reloadData()
    }
  }

  fileprivate func stopObserving() {
    listener?.remove()
  }

  fileprivate func baseQuery() -> Query {
    return Firestore.firestore().collection("restaurants").limit(to: 50)
  }

  private lazy var filters: (navigationController: UINavigationController,
                             filtersController: FiltersViewController) = {
    FiltersViewController.fromStoryboard(delegate: self)
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    backgroundView.image = UIImage(named: "pizza-monster")!
    backgroundView.contentMode = .scaleAspectFit
    backgroundView.alpha = 0.5
    tableView.backgroundView = backgroundView
    tableView.tableFooterView = UIView()

    // Blue bar with white color
    navigationController?.navigationBar.barTintColor =
      UIColor(red: 0x3D / 0xFF, green: 0x5A / 0xFF, blue: 0xFE / 0xFF, alpha: 1.0)
    navigationController?.navigationBar.isTranslucent = false
    navigationController?.navigationBar.titleTextAttributes =
      [NSAttributedString.Key.foregroundColor: UIColor.white]

    tableView.dataSource = self
    tableView.delegate = self
    query = baseQuery()
    stackViewHeightConstraint.constant = 0
    activeFiltersStackView.isHidden = true

    navigationController?.navigationBar.barStyle = .black
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    setNeedsStatusBarAppearanceUpdate()
    observeQuery()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    let auth = FUIAuth.defaultAuthUI()!
    if auth.auth?.currentUser == nil {
      let emailAuthProvider = FUIEmailAuth()
      auth.providers = [emailAuthProvider]
      present(auth.authViewController(), animated: true, completion: nil)
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    stopObserving()
  }

  @IBAction func didTapPopulateButton(_ sender: Any) {
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

      let collection = Firestore.firestore().collection("restaurants")

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

      let batch = Firestore.firestore().batch()
      guard let user = Auth.auth().currentUser else { continue }
      var average: Float = 0
      for _ in 0 ..< 10 {
        let rating = Int(arc4random_uniform(5) + 1)
        average += Float(rating) / 10
        let text = rating > 3 ? "good" : "food was too spicy"
        let review = Review(rating: rating,
                            userID: user.uid,
                            username: user.displayName ?? "Anonymous",
                            text: text,
                            date: Timestamp())
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

  @IBAction func didTapClearButton(_ sender: Any) {
    filters.filtersController.clearFilters()
    controller(
      filters.filtersController,
      didSelectCategory: nil,
      city: nil,
      price: nil,
      sortBy: nil
    )
  }

  @IBAction func didTapFilterButton(_ sender: Any) {
    present(filters.navigationController, animated: true, completion: nil)
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    set {}
    get {
      return .lightContent
    }
  }

  deinit {
    listener?.remove()
  }

  // MARK: - UITableViewDataSource

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "RestaurantTableViewCell",
                                             for: indexPath) as! RestaurantTableViewCell
    let restaurant = restaurants[indexPath.row]
    cell.populate(restaurant: restaurant)
    return cell
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return restaurants.count
  }

  // MARK: - UITableViewDelegate

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let controller = RestaurantDetailViewController.fromStoryboard()
    controller.titleImageURL = restaurants[indexPath.row].photo
    controller.restaurant = restaurants[indexPath.row]
    controller.restaurantReference = documents[indexPath.row].reference
    navigationController?.pushViewController(controller, animated: true)
  }
}

extension RestaurantsTableViewController: FiltersViewControllerDelegate {
  func query(withCategory category: String?, city: String?, price: Int?, sortBy: String?) -> Query {
    var filtered = baseQuery()

    if category == nil, city == nil, price == nil, sortBy == nil {
      stackViewHeightConstraint.constant = 0
      activeFiltersStackView.isHidden = true
    } else {
      stackViewHeightConstraint.constant = 44
      activeFiltersStackView.isHidden = false
    }

    // Advanced queries

    if let category = category, !category.isEmpty {
      filtered = filtered.whereField("category", isEqualTo: category)
    }

    if let city = city, !city.isEmpty {
      filtered = filtered.whereField("city", isEqualTo: city)
    }

    if let price = price {
      filtered = filtered.whereField("price", isEqualTo: price)
    }

    if let sortBy = sortBy, !sortBy.isEmpty {
      filtered = filtered.order(by: sortBy)
    }

    return filtered
  }

  func controller(_ controller: FiltersViewController,
                  didSelectCategory category: String?,
                  city: String?,
                  price: Int?,
                  sortBy: String?) {
    let filtered = query(withCategory: category, city: city, price: price, sortBy: sortBy)

    if let category = category, !category.isEmpty {
      categoryFilterLabel.text = category
      categoryFilterLabel.isHidden = false
    } else {
      categoryFilterLabel.isHidden = true
    }

    if let city = city, !city.isEmpty {
      cityFilterLabel.text = city
      cityFilterLabel.isHidden = false
    } else {
      cityFilterLabel.isHidden = true
    }

    if let price = price {
      priceFilterLabel.text = priceString(from: price)
      priceFilterLabel.isHidden = false
    } else {
      priceFilterLabel.isHidden = true
    }

    query = filtered
    observeQuery()
  }
}

class RestaurantTableViewCell: UITableViewCell {
  @IBOutlet private var thumbnailView: UIImageView!

  @IBOutlet private var nameLabel: UILabel!

  @IBOutlet var starsView: ImmutableStarsView!

  @IBOutlet private var cityLabel: UILabel!

  @IBOutlet private var categoryLabel: UILabel!

  @IBOutlet private var priceLabel: UILabel!

  func populate(restaurant: Restaurant) {
    // Displaying data, part two

    nameLabel.text = restaurant.name
    cityLabel.text = restaurant.city
    categoryLabel.text = restaurant.category
    starsView.rating = Int(restaurant.averageRating.rounded())
    priceLabel.text = priceString(from: restaurant.price)

    let image = restaurant.photo
    thumbnailView.sd_setImage(with: image)
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    thumbnailView.sd_cancelCurrentImageLoad()
  }
}
