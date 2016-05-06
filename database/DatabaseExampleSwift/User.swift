//
//  User.swift
//  DatabaseExample
//
//  Created by Ibrahim Ulukaya on 5/5/16.
//  Copyright © 2016 Google Inc. All rights reserved.
//

import UIKit

class User: NSObject {
  var username: String

  init(username: String) {
    self.username = username
  }

  convenience override init() {
    self.init(username:  "")
  }
}
