//
//  Copyright (c) 2021 Google Inc.
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

import Foundation
import Firebase

struct Post: Identifiable {
  var id: String
  var uid: String
  var author: String
  var title: String
  var body: String
  var starCount: Int
  var starDictionary: [String: Bool]

  init(id: String, uid: String, author: String, title: String, body: String) {
    self.id = id
    self.uid = uid
    self.author = author
    self.title = title
    self.body = body
    starCount = 0
    starDictionary = [:]
  }

  init?(id: String, dict: [String: Any]) {
    guard let uid = dict["uid"] as? String else { return nil }
    guard let author = dict["author"] as? String else { return nil }
    guard let title = dict["title"] as? String else { return nil }
    guard let body = dict["body"] as? String else { return nil }
    let starCount = dict["starCount"] as? Int ?? 0

    self.id = id
    self.uid = uid
    self.author = author
    self.title = title
    self.body = body
    self.starCount = starCount
    starDictionary = [:]
  }

  init() {
    self.init(id: "", uid: "", author: "", title: "", body: "")
  }

  mutating func didTapStarButton(isStarred: Bool) {
    let ref: DatabaseReference = {
      Database.database().reference()
    }()
    if isStarred {
      // add current user to the post.starDictionary
      starDictionary[uid] = true
      ref.child("/posts/\(id)/starDictionary").setValue(starDictionary)
      ref.child("/user-posts/\(uid)/\(id)/starDictionary").setValue(starDictionary)
      // increment starCount on current post
      ref.child("/posts/\(id)/starCount").setValue(starCount + 1)
      ref.child("/user-posts/\(uid)/\(id)/starCount").setValue(starCount + 1)
    } else {
      // remove current user from the post.starDictionary
      starDictionary.removeValue(forKey: uid)
      ref.child("/posts/\(id)/starDictionary").setValue(starDictionary)
      ref.child("/user-posts/\(uid)/\(id)/starDictionary").setValue(starDictionary)
      // decrement starCount on current post
      ref.child("/posts/\(id)/starCount").setValue(starCount - 1)
      ref.child("/user-posts/\(uid)/\(id)/starCount").setValue(starCount - 1)
    }
  }
}
