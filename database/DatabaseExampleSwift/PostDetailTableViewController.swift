//
//  PostDetailTableViewController.swift
//  DatabaseExample
//
//  Created by Ibrahim Ulukaya on 5/6/16.
//  Copyright © 2016 Google Inc. All rights reserved.
//

import UIKit
import Firebase

class PostDetailTableViewController: UITableViewController {

  let kSectionSend = 2
  let kSectionComments = 1
  let kSectionPost = 0

  var postKey = ""
  var comments: Array<FIRDataSnapshot> = []
  let commentField: UITextField? = nil
  var post: Post = Post()
  let ref: FIRDatabaseReference = FIRDatabase().reference()
  var postRef: FIRDatabaseReference!
  var commentsRef : FIRDatabaseReference!
  var _refHandle: FIRDatabaseHandle?


  override func viewDidLoad() {
    super.viewDidLoad()
    postRef = ref.child("posts").child(postKey)
    commentsRef = ref.child("post-comments").child(postKey)
  }

  override func viewWillAppear(animated: Bool) {
    self.comments.removeAll()
    // Listen for new comments in the Firebase database
    commentsRef.observeEventType(.ChildAdded, withBlock: { (snapshot) -> Void in
      self.comments.append(snapshot)
      self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.comments.count-1, inSection: 1)], withRowAnimation: UITableViewRowAnimation.Automatic)
    })
    // Listen for deleted comments in the Firebase database
    self.ref.child("messages").observeEventType(.ChildRemoved, withBlock: { (snapshot) -> Void in
      let index = self.indexOfMessage(snapshot)
      self.comments.removeAtIndex(index)
      self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 1)], withRowAnimation: UITableViewRowAnimation.Automatic)
    })
    _refHandle = postRef.observeEventType(.Value) { (snapshot) in
      let postDict = snapshot.value
      post.uid = postDict["uid"]
      post.author = postDict["author"]
      post.title = postDict["title"]
      post.body = postDict["body"]
      tableView.reloadData()
    }
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
    postRef.removeObserverWithHandle(_refHandle)
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
      let user = snapshot.value
      let username = user!["username"]
      let comment = ["uid": uid,
                     "author": username,
                     "text": self.commentField.text]
      commentsRef.childByAutoId().setValue(comment)
      self.commentField.text = ""
    })
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell: UITableViewCell
    switch indexPath.section {
    case kSectionPost:
      cell = tableView.dequeueReusableCellWithIdentifier("post")!
      let authorLabel: UILabel = cell.viewWithTag(2) as! UILabel
      let title: UILabel = cell.viewWithTag(3) as! UILabel
      let body: UITextView = cell.viewWithTag(6) as! UITextView
      authorLabel.text = post.author
      title.text = post.title
      body.text = post.body
    case kSectionComments:
      cell = tableView.dequeueReusableCellWithIdentifier("comment")!
      let comment = comments[indexPath.row].value
      cell.textLabel?.text = comment!["author"]
      cell.detailTextLabel?.text = comment["text"]
    case kSectionSend:
      cell = tableView.dequeueReusableCellWithIdentifier("send")
      commentField = cell.viewWithTag(7)
    default:
      break
    }
    return cell!
  }

  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    if indexPath.section = kSectionPost {
      return 150
    }
    return 50
  }}
