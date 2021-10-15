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
import SDWebImage
import Firebase

class RestaurantDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
  NewReviewViewControllerDelegate {
  var titleImageURL: URL?
  var restaurant: Restaurant?
  var restaurantReference: DocumentReference?

  var localCollection: LocalCollection<Review>!

  static func fromStoryboard(_ storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil))
    -> RestaurantDetailViewController {
    let controller = storyboard
      .instantiateViewController(
        withIdentifier: "RestaurantDetailViewController"
      ) as! RestaurantDetailViewController
    return controller
  }

  @IBOutlet var tableView: UITableView!
  @IBOutlet var titleView: RestaurantTitleView!

  let backgroundView = UIImageView()

  override func viewDidLoad() {
    super.viewDidLoad()

    title = restaurant?.name
    navigationController?.navigationBar.tintColor = UIColor.white

    backgroundView.image = UIImage(named: "pizza-monster")!
    backgroundView.contentScaleFactor = 2
    backgroundView.contentMode = .bottom
    tableView.backgroundView = backgroundView
    tableView.tableFooterView = UIView()

    tableView.dataSource = self
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 140

    let query = restaurantReference!.collection("ratings")
    localCollection = LocalCollection(query: query) { [unowned self] changes in
      if self.localCollection.count == 0 {
        self.tableView.backgroundView = self.backgroundView
        return
      } else {
        self.tableView.backgroundView = nil
      }
      var indexPaths: [IndexPath] = []

      // Only care about additions in this block, updating existing reviews probably not important
      // as there's no way to edit reviews.
      for addition in changes.filter({ $0.type == .added }) {
        let index = self.localCollection.index(of: addition.document)!
        let indexPath = IndexPath(row: index, section: 0)
        indexPaths.append(indexPath)
      }
      self.tableView.insertRows(at: indexPaths, with: .automatic)
    }
  }

  deinit {
    localCollection.stopListening()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    localCollection.listen()
    titleView.populate(restaurant: restaurant!)
    if let url = titleImageURL {
      titleView.populateImage(url: url)
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    set {}
    get {
      return .lightContent
    }
  }

  @IBAction func didTapAddButton(_ sender: Any) {
    let controller = NewReviewViewController.fromStoryboard()
    controller.delegate = self
    navigationController?.pushViewController(controller, animated: true)
  }

  // MARK: - UITableViewDataSource

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return localCollection.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewTableViewCell",
                                             for: indexPath) as! ReviewTableViewCell
    let review = localCollection[indexPath.row]
    cell.populate(review: review)
    return cell
  }

  // MARK: - NewReviewViewControllerDelegate

  func reviewController(_ controller: NewReviewViewController,
                        didSubmitFormWithReview review: Review) {
    guard let reference = restaurantReference else { return }
    let reviewsCollection = reference.collection("ratings")
    let newReviewReference = reviewsCollection.document()

    // Writing data in a transaction

    let firestore = Firestore.firestore()
    firestore.runTransaction({ (transaction, errorPointer) -> Any? in

      // Read data from Firestore inside the transaction, so we don't accidentally
      // update using stale client data. Error if we're unable to read here.
      let restaurantSnapshot: DocumentSnapshot
      do {
        restaurantSnapshot = try transaction.getDocument(reference)
      } catch let error as NSError {
        errorPointer?.pointee = error
        return nil
      }

      // Error if the restaurant data in Firestore has somehow changed or is malformed.
      let maybeRestaurant: Restaurant?
      do {
        maybeRestaurant = try restaurantSnapshot.data(as: Restaurant.self)
      } catch {
        errorPointer?.pointee = NSError(domain: "FriendlyEatsErrorDomain", code: 0, userInfo: [
          NSLocalizedDescriptionKey: "Unable to read restaurant at Firestore path: \(reference.path): \(error)",
        ])
        return nil
      }

      guard let restaurant = maybeRestaurant else {
        errorPointer?.pointee = NSError(domain: "FriendlyEatsErrorDomain", code: 0, userInfo: [
          NSLocalizedDescriptionKey: "Missing restaurant at Firestore path: \(reference.path)",
        ])
        return nil
      }

      // Update the restaurant's rating and rating count and post the new review at the
      // same time.
      let newAverage = (Float(restaurant.ratingCount) * restaurant
        .averageRating + Float(review.rating))
        / Float(restaurant.ratingCount + 1)

      do {
        try transaction.setData(from: review, forDocument: newReviewReference)
      } catch let error as NSError {
        errorPointer?.pointee = error
        return nil
      }
      transaction.updateData([
        "numRatings": restaurant.ratingCount + 1,
        "avgRating": newAverage,
      ], forDocument: reference)
      return nil
    }) { object, error in
      if let error = error {
        print(error)
      } else {
        // Pop the review controller on success
        if self.navigationController?.topViewController?
          .isKind(of: NewReviewViewController.self) ?? false {
          self.navigationController?.popViewController(animated: true)
        }
      }
    }
  }
}

class RestaurantTitleView: UIView {
  @IBOutlet var nameLabel: UILabel!

  @IBOutlet var categoryLabel: UILabel!

  @IBOutlet var cityLabel: UILabel!

  @IBOutlet var priceLabel: UILabel!

  @IBOutlet var starsView: ImmutableStarsView! {
    didSet {
      starsView.highlightedColor = UIColor.white.cgColor
    }
  }

  @IBOutlet var titleImageView: UIImageView! {
    didSet {
      let gradient = CAGradientLayer()
      gradient.colors = [
        UIColor(red: 0, green: 0, blue: 0, alpha: 0.6).cgColor,
        UIColor.clear.cgColor,
      ]
      gradient.locations = [0.0, 1.0]

      gradient.startPoint = CGPoint(x: 0, y: 1)
      gradient.endPoint = CGPoint(x: 0, y: 0)
      gradient.frame = CGRect(x: 0,
                              y: 0,
                              width: UIScreen.main.bounds.width,
                              height: titleImageView.bounds.height)

      titleImageView.layer.insertSublayer(gradient, at: 0)
      titleImageView.contentMode = .scaleAspectFill
      titleImageView.clipsToBounds = true
    }
  }

  func populateImage(url: URL) {
    titleImageView.sd_setImage(with: url)
  }

  func populate(restaurant: Restaurant) {
    nameLabel.text = restaurant.name
    starsView.rating = Int(restaurant.averageRating.rounded())
    categoryLabel.text = restaurant.category
    cityLabel.text = restaurant.city
    priceLabel.text = priceString(from: restaurant.price)
  }
}

class ReviewTableViewCell: UITableViewCell {
  @IBOutlet var usernameLabel: UILabel!

  @IBOutlet var reviewContentsLabel: UILabel!

  @IBOutlet var starsView: ImmutableStarsView!

  func populate(review: Review) {
    usernameLabel.text = review.username
    reviewContentsLabel.text = review.text
    starsView.rating = review.rating
  }
}
