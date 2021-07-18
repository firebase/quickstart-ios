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

import SwiftUI
import Firebase

class PostViewModel: ObservableObject, Identifiable {
  @Published var id: String
  @Published var uid: String
  @Published var author: String
  @Published var title: String
  @Published var body: String
  @Published var starCount: Int
  @Published var userIDsStarredBy: [String: Bool]

  private lazy var ref: DatabaseReference = {
    Database.database().reference()
  }()

  init(id: String, uid: String, author: String, title: String, body: String) {
    self.id = id
    self.uid = uid
    self.author = author
    self.title = title
    self.body = body
    self.starCount = 0
    self.userIDsStarredBy = [:]
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
    self.userIDsStarredBy = [:]
  }

  func getCurrentUserID() -> String {
    guard let currentUserID = Auth.auth().currentUser?.uid else { return "" }
    return currentUserID
  }

  func didTapStarButton() {

    let currentUserID = self.getCurrentUserID()
    let isStarred = userIDsStarredBy["\(currentUserID)"] ?? false
    if isStarred {
      // TODO: add current user to the post.starDictionary
      userIDsStarredBy.removeValue(forKey: uid)
    } else {
      // TODO: remove current user from the post.starDictionary
      userIDsStarredBy[uid] = true
    }
  }
}
