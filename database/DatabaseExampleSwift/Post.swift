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

class Post: NSObject {
  var uid: String
  var author: String
  var title: String
  var body: String
  var starCount: AnyObject?
  var stars: Dictionary<String, Bool>?

  init(uid: String, author: String, title: String, body: String) {
    self.uid = uid
    self.author = author
    self.title = title
    self.body = body
    self.starCount = 0
  }

  convenience override init() {
    self.init(uid: "", author: "", title: "", body:  "")
  }
}
