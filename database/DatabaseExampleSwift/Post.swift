//
//  Post.swift
//  DatabaseExample
//
//  Created by Ibrahim Ulukaya on 5/5/16.
//  Copyright © 2016 Google Inc. All rights reserved.
//

import UIKit

class Post: NSObject {
  var uid: String
  var author: String
  var title: String
  var body: String
  var starCount: Int?
  var stars: Dictionary<String, Bool>?

  init(uid: String, author: String, title: String, body: String) {
    self.uid = uid
    self.author = author
    self.title = title
    self.body = body
  }

  convenience override init() {
    self.init(uid: "", author: "", title: "", body:  "")
  }
}
