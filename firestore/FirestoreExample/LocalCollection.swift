//
//  Copyright (c) 2016 Google Inc.
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

import Firebase
import FirebaseFirestoreSwift

final class LocalCollection<T: Codable> {
  private(set) var items: [T]
  private(set) var documents: [DocumentSnapshot] = []
  let query: Query

  private let updateHandler: ([DocumentChange]) -> Void

  private var listener: ListenerRegistration? {
    didSet {
      oldValue?.remove()
    }
  }

  var count: Int {
    return items.count
  }

  subscript(index: Int) -> T {
    return items[index]
  }

  init(query: Query, updateHandler: @escaping ([DocumentChange]) -> Void) {
    items = []
    self.query = query
    self.updateHandler = updateHandler
  }

  func index(of document: DocumentSnapshot) -> Int? {
    for i in 0 ..< documents.count {
      if documents[i].documentID == document.documentID {
        return i
      }
    }

    return nil
  }

  func listen() {
    guard listener == nil else { return }
    listener = query.addSnapshotListener { [unowned self] querySnapshot, error in
      guard let snapshot = querySnapshot else {
        print("Error fetching snapshot results: \(error!)")
        return
      }
      let models = snapshot.documents.map { (document) -> T in
        let maybeModel: T?
        do {
          maybeModel = try document.data(as: T.self)
        } catch {
          fatalError("Unable to initialize type \(T.self) from data \(document.data()): \(error)")
        }

        if let model = maybeModel {
          return model
        } else {
          fatalError("Missing document of type \(T.self) at \(document.reference.path)")
        }
      }
      self.items = models
      self.documents = snapshot.documents
      self.updateHandler(snapshot.documentChanges)
    }
  }

  func stopListening() {
    listener = nil
  }

  deinit {
    stopListening()
  }
}
