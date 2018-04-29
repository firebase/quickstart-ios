//
//  Copyright (c) 2015 Google Inc.
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
import FirebaseUI

@objc(PostListViewController)
class PostListViewController: UIViewController, UITableViewDelegate {

  // [START define_database_reference]
  var ref: DatabaseReference!
  // [END define_database_reference]

  var dataSource: FUITableViewDataSource?

  @IBOutlet weak var tableView: UITableView!

  override func viewDidLoad() {
    super.viewDidLoad()

    // [START create_database_reference]
    ref = Database.database().reference()
    // [END create_database_reference]

    let identifier = "post"
    let nib = UINib(nibName: "PostTableViewCell", bundle: nil)
    tableView.register(nib, forCellReuseIdentifier: identifier)

    dataSource = FUITableViewDataSource(query: getQuery()) { (tableView, indexPath, snap) -> UITableViewCell in
      let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! PostTableViewCell

      guard let post = Post(snapshot: snap) else { return cell }
      cell.authorImage.image = UIImage(named: "ic_account_circle")
      cell.authorLabel.text = post.author
      var imageName = "ic_star_border"
      if (post.stars?[self.getUid()]) != nil {
        imageName = "ic_star"
      }
      cell.starButton.setImage(UIImage(named: imageName), for: .normal)
      if let starCount = post.starCount {
        cell.numStarsLabel.text = "\(starCount)"
      }
      cell.postTitle.text = post.title
      cell.postBody.text = post.body
      return cell
    }

    dataSource?.bind(to: tableView)
    tableView.delegate = self
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.tableView.reloadData()
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    performSegue(withIdentifier: "detail", sender: indexPath)
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 150
  }

  func getUid() -> String {
    return (Auth.auth().currentUser?.uid)!
  }

  func getQuery() -> DatabaseQuery {
    return self.ref
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    guard let indexPath: IndexPath = sender as? IndexPath else { return }
    guard let detail: PostDetailTableViewController = segue.destination as? PostDetailTableViewController else {
      return
    }
    if let dataSource = dataSource {
      detail.postKey = dataSource.snapshot(at: indexPath.row).key
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    getQuery().removeAllObservers()
  }
}
