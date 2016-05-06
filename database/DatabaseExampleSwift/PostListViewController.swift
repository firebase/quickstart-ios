//
//  PostLitViewController.swift
//  DatabaseExample
//
//  Created by Ibrahim Ulukaya on 5/5/16.
//  Copyright © 2016 Google Inc. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseUI
import FirebaseDatabase

@objc(PostListViewController)
class PostListViewController: UIViewController, UITableViewDelegate {

  var ref: FIRDatabaseReference!
  var dataSource: FirebaseTableViewDataSource?

  @IBOutlet weak var tableView: UITableView!

  override func viewDidLoad() {
    super.viewDidLoad()

    ref = FIRDatabase().reference()

    dataSource = FirebaseTableViewDataSource.init(query: getQuery(), modelClass: Post.self, nibNamed: "PostTableViewCell", cellReuseIdentifier: "postCell", view: self.tableView)

    dataSource?.populateCellWithBlock(){
      let cell = $0 as! PostTableViewCell
      let post = $1 as! Post
      cell.authorImage.image = UIImage.init(named: "ic_account_circle")
      cell.authorLabel.text = post.author
      var imageName = "ic_star_border"
      if (post.stars?[self.getUid()]) != nil {
        imageName = "ic_star"
      }
      cell.starImage.image = UIImage.init(named: imageName)
      cell.numStarsLabel.text = String(post.starCount)
      cell.postTitle.text = post.title
      cell.postBody.text = post.body
    }

    tableView.dataSource = dataSource
    tableView.delegate = self
  }

  override func viewWillAppear(animated: Bool) {
    navigationItem.rightBarButtonItem?.title = "Logout"
  }

  func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
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
}
