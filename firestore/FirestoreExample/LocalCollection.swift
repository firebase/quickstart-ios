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

import FirebaseFirestore

/**
 * A helper class that manages a local cache of Firestore documents
 * and syncs changes from the server to the local collection.
 *
 * This class is generic and can work with any Codable model type.
 * It maintains both the decoded model objects and the associated
 * DocumentSnapshots for extended functionality.
 */
final class LocalCollection<T: Codable> {
  /// The locally cached model objects
  private(set) var items: [T]

  /// The Firestore document snapshots associated with items
  private(set) var documents: [DocumentSnapshot] = []

  /// The Firestore query used to retrieve documents
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

  /**
   * Finds the index of a document in the local collection by its ID.
   *
   * - Parameter document: The Firestore document snapshot to locate
   * - Returns: The index of the document in the collection if found, or nil if not present
   *
   * - Note: This performs a linear search through the documents array.
   *         For large collections, consider using a dictionary-based approach instead.
   */
  func index(of document: DocumentSnapshot) -> Int? {
    for i in 0 ..< documents.count {
      if documents[i].documentID == document.documentID {
        return i
      }
    }

    return nil
  }

  /**
   * Starts real-time listening for changes to the Firestore query.
   *
   * This method sets up a snapshot listener that will automatically update
   * the local collection whenever changes occur in Firestore. The listener
   * decodes documents into model objects of type T and calls the update handler
   * with any document changes.
   *
   * - Note: If a listener is already active, this method does nothing.
   *         Call `stopListening()` first if you need to change the query.
   */
  func listen() {
    guard listener == nil else { return }
    listener = query.addSnapshotListener { [unowned self] querySnapshot, error in
      guard let snapshot = querySnapshot else {
        print("Error fetching snapshot results: \(error!)")
        return
      }
      let models = snapshot.documents.map { document -> T in
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
