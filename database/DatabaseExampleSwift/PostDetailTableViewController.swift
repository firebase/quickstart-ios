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

@objc(PostDetailTableViewController)
class PostDetailTableViewController: UITableViewController {

  let kSectionSend = 2
  let kSectionComments = 1
  let kSectionPost = 0

  var postKey = ""
  var comments: Array<FIRDataSnapshot> = []
  var commentField: UITextField? = nil
  let post: Post = Post()
  lazy var ref: FIRDatabaseReference = FIRDatabase.database().reference()
  var postRef: FIRDatabaseReference!
  var commentsRef : FIRDatabaseReference!
  var refHandle: FIRDatabaseHandle?


  override func viewDidLoad() {
    super.viewDidLoad()
    postRef = ref.child("posts").child(postKey)
    commentsRef = ref.child("post-comments").child(postKey)
    let nib = UINib(nibName: "PostTableViewCell", bundle: nil)
    tableView.registerNib(nib, forCellReuseIdentifier: "post")
  }

  override func viewWillAppear(animated: Bool) {
    comments.removeAll()
    // [START child_event_listener]
    // Listen for new comments in the Firebase database
    commentsRef.observeEventType(.ChildAdded, withBlock: { (snapshot) -> Void in
      self.comments.append(snapshot)
      self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.comments.count-1, inSection: 1)], withRowAnimation: UITableViewRowAnimation.Automatic)
    })
    // Listen for deleted comments in the Firebase database
    commentsRef.observeEventType(.ChildRemoved, withBlock: { (snapshot) -> Void in
      let index = self.indexOfMessage(snapshot)
      self.comments.removeAtIndex(index)
      self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 1)], withRowAnimation: UITableViewRowAnimation.Automatic)
    })
    // [END child_event_listener]

    // [START post_value_event_listener]
    refHandle = postRef.observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) in
      let postDict = snapshot.value as! [String : AnyObject]
      // [START_EXCLUDE]
      self.post.setValuesForKeysWithDictionary(postDict)
      self.tableView.reloadData()
      self.navigationItem.title = self.post.title
      // [END_EXCLUDE]
    })
    // [END post_value_event_listener]
  }

  func indexOfMessage(snapshot: FIRDataSnapshot) -> Int {
    var index = 0
    for  comment in self.comments {
      if (snapshot.key == comment.key) {
        return index
      }
      index += 1
    }
    return -1
  }

  override func viewWillDisappear(animated: Bool) {
    if let refHandle = refHandle {
      postRef.removeObserverWithHandle(refHandle)
    }
    commentsRef.removeAllObservers()
  }

  // UITableViewDataSource protocol methods
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 3
  }

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch section {
    case kSectionPost, kSectionSend:
      return 1
    case kSectionComments:
      return comments.count
    default:
      return 0
    }
  }

  @IBAction func didTapSend(sender: AnyObject) {
    let uid = FIRAuth.auth()?.currentUser?.uid
    FIRDatabase.database().reference().child("users").child(uid!).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
      if let uid = uid, commentField = self.commentField, user = snapshot.value as? [String : AnyObject] {
        let comment = [
          "uid": uid,
          "author": user["username"] as! String,
          "text": commentField.text!
        ]
        self.commentsRef.childByAutoId().setValue(comment)
        commentField.text = ""
      }
    })
  }
  override func tableView(tableView: UITableView,
                          cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell: UITableViewCell

    switch indexPath.section {
    case kSectionPost:
      cell = tableView.dequeueReusableCellWithIdentifier("post")!
      if let uid = FIRAuth.auth()?.currentUser?.uid {
        let postcell = cell as! PostTableViewCell
        let imageName = post.stars == nil || post.stars![uid] == nil ? "ic_star_border" : "ic_star"
        postcell.authorLabel.text = post.author
        postcell.postTitle.text = post.title
        postcell.postBody.text = post.body
        postcell.starButton.setImage(UIImage(named: imageName), forState: .Normal)
        if let starCount = post.starCount {
          postcell.numStarsLabel.text = "\(starCount)"
        }
        postcell.postKey = postKey;
      }
    case kSectionComments:
      cell = tableView.dequeueReusableCellWithIdentifier("comment")!
      let commentDict = comments[indexPath.row].value as! [String : AnyObject]
      if let text = cell.textLabel, detail = cell.detailTextLabel,
        author = commentDict["author"], commentText = commentDict["text"] {
        detail.text = String(author)
        text.text = String(commentText)
      }
    default: // kSectionSend
      cell = tableView.dequeueReusableCellWithIdentifier("send")!
      commentField = cell.viewWithTag(7) as! UITextField?
      break
    }
    return cell
  }

  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    if indexPath.section == kSectionPost {
      return 160
    }
    return 56
  }
}
