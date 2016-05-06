//
//  Comment.swift
//  DatabaseExample
//
//  Created by Ibrahim Ulukaya on 5/5/16.
//  Copyright © 2016 Google Inc. All rights reserved.
//

import UIKit

class Comment: NSObject {
  var uid: String
  var author: String
  var text: String

  init(uid: String, author: String, text: String) {
    self.uid = uid
    self.author = author
    self.text = text
  }

  convenience override init() {
    self.init(uid: "", author: "", text: "")
  }
}
