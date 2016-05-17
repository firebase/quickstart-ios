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
  var ref: FIRDatabaseReference!
  // [END define_database_reference]

  var dataSource: FirebaseTableViewDataSource?

  @IBOutlet weak var tableView: UITableView!

  override func viewDidLoad() {
    super.viewDidLoad()

    // [START create_database_reference]
    ref = FIRDatabase.database().reference()
    // [END create_database_reference]

    dataSource = FirebaseTableViewDataSource.init(query: getQuery(),
                                                  modelClass: Post.self,
                                                  nibNamed: "PostTableViewCell",
                                                  cellReuseIdentifier: "post",
                                                  view: self.tableView)

    dataSource?.populateCellWithBlock(){
      let cell = $0 as! PostTableViewCell
      let post = $1 as! Post
      cell.authorImage.image = UIImage.init(named: "ic_account_circle")
      cell.authorLabel.text = post.author
      var imageName = "ic_star_border"
      if (post.stars?[self.getUid()]) != nil {
        imageName = "ic_star"
      }
      cell.starButton.setImage(UIImage.init(named: imageName), forState: .Normal)
      if let starCount = post.starCount {
        cell.numStarsLabel.text = "\(starCount)"
      }
      cell.postTitle.text = post.title
      cell.postBody.text = post.body
    }

    tableView.dataSource = dataSource
    tableView.delegate = self
  }

  override func viewWillAppear(animated: Bool) {
    self.tableView.reloadData()
  }

  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    performSegueWithIdentifier("detail", sender: indexPath)
  }

  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 150
  }

  func getUid() -> String {
    return (FIRAuth.auth()?.currentUser?.uid)!
  }

  func getQuery() -> FIRDatabaseQuery {
    return self.ref
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    let path: NSIndexPath = sender as! NSIndexPath
    let detail: PostDetailTableViewController = segue.destinationViewController as! PostDetailTableViewController
    let source = self.dataSource
    let snapshot: FIRDataSnapshot = (source?.objectAtIndex(UInt(path.row)))! as! FIRDataSnapshot
    detail.postKey = snapshot.key
  }
}
