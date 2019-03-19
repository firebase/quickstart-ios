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
class PostDetailTableViewController: UITableViewController, UITextFieldDelegate {

  let kSectionComments = 2
  let kSectionSend = 1
  let kSectionPost = 0

  var postKey = ""
  var comments: Array<DataSnapshot> = []
  var commentField: UITextField? = nil
  let post: Post = Post()
  lazy var ref: DatabaseReference = Database.database().reference()
  var postRef: DatabaseReference!
  var commentsRef: DatabaseReference!
  var refHandle: DatabaseHandle?

  // UITextViewDelegate protocol method
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    postRef = ref.child("posts").child(postKey)
    commentsRef = ref.child("post-comments").child(postKey)
    let nib = UINib(nibName: "PostTableViewCell", bundle: nil)
    tableView.register(nib, forCellReuseIdentifier: "post")
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    comments.removeAll()
    // [START child_event_listener]
    // Listen for new comments in the Firebase database
    commentsRef.observe(.childAdded, with: { (snapshot) -> Void in
      self.comments.append(snapshot)
      self.tableView.insertRows(at: [IndexPath(row: self.comments.count-1, section: self.kSectionComments)], with: UITableView.RowAnimation.automatic)
    })
    // Listen for deleted comments in the Firebase database
    commentsRef.observe(.childRemoved, with: { (snapshot) -> Void in
      let index = self.indexOfMessage(snapshot)
      self.comments.remove(at: index)
      self.tableView.deleteRows(at: [IndexPath(row: index, section: self.kSectionComments)], with: UITableView.RowAnimation.automatic)
    })
    // [END child_event_listener]

    // [START post_value_event_listener]
    refHandle = postRef.observe(DataEventType.value, with: { (snapshot) in
      let postDict = snapshot.value as? [String : AnyObject] ?? [:]
      // [START_EXCLUDE]
      self.post.setValuesForKeys(postDict)
      self.tableView.reloadData()
      self.navigationItem.title = self.post.title
      // [END_EXCLUDE]
    })
    // [END post_value_event_listener]
  }

  func indexOfMessage(_ snapshot: DataSnapshot) -> Int {
    var index = 0
    for  comment in self.comments {
      if snapshot.key == comment.key {
        return index
      }
      index += 1
    }
    return -1
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if let refHandle = refHandle {
      postRef.removeObserver(withHandle: refHandle)
    }
    commentsRef.removeAllObservers()
    if let uid = Auth.auth().currentUser?.uid {
      Database.database().reference().child("users").child(uid).removeAllObservers()
    }
  }

  // UITableViewDataSource protocol methods
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 3
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch section {
    case kSectionPost, kSectionSend:
      return 1
    case kSectionComments:
      return comments.count
    default:
      return 0
    }
  }

  @IBAction func didTapSend(_ sender: UIButton) {
    _ = textFieldShouldReturn(commentField!)
    commentField?.isEnabled = false
    sender.isEnabled = false
    if let uid = Auth.auth().currentUser?.uid {
      Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
        if let commentField = self.commentField, let user = snapshot.value as? [String : AnyObject] {
          let comment = [
            "uid": uid,
            "author": user["username"] as? String ?? "",
            "text": commentField.text!
          ]
          self.commentsRef.childByAutoId().setValue(comment)
          commentField.text = ""
          commentField.isEnabled = true
          sender.isEnabled = true
        }
      })
    }
  }

  override func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell: UITableViewCell

    switch indexPath.section {
    case kSectionPost:
      cell = tableView.dequeueReusableCell(withIdentifier: "post", for: indexPath)
      if let uid = Auth.auth().currentUser?.uid {
        guard let postcell = cell as? PostTableViewCell else {
          break
        }
        let imageName = post.stars == nil || post.stars![uid] == nil ? "ic_star_border" : "ic_star"
        postcell.authorLabel.text = post.author
        postcell.postTitle.text = post.title
        postcell.postBody.text = post.body
        postcell.starButton.setImage(UIImage(named: imageName), for: .normal)
        if let starCount = post.starCount {
          postcell.numStarsLabel.text = "\(starCount)"
        }
        postcell.postKey = postKey
      }
    case kSectionComments:
      cell = tableView.dequeueReusableCell(withIdentifier: "comment", for: indexPath)
      let commentDict = comments[indexPath.row].value as? [String : AnyObject]
      if let text = cell.textLabel, let detail = cell.detailTextLabel,
        let author = commentDict?["author"], let commentText = commentDict?["text"] {
        detail.text = String(describing: author)
        text.text = String(describing: commentText)
      }
    default: // kSectionSend
      cell = tableView.dequeueReusableCell(withIdentifier: "send", for: indexPath)
      commentField = cell.viewWithTag(7) as? UITextField
      break
    }
    return cell
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.section == kSectionPost {
      return 160
    }
    return 56
  }
}
