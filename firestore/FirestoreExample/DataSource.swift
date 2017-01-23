//
//  DataSource.swift
//  FirestoreExample
//
//  Created by Morgan Chen on 1/17/17.
//  Copyright © 2017 Morgan Chen. All rights reserved.
//

import UIKit

import Firestore

class LocalCollection<T: Hashable> where T: DocumentSerializable {

  private(set) var items: [T]
  private(set) var documents: [Document] = []
  let query: QueryReference

  let updateHandler: (Diff<T>) -> ()

  var listener: QueryListener? {
    didSet {
      oldValue?.stopListening()
    }
  }

  var count: Int {
    return self.items.count
  }

  subscript(index: Int) -> T {
    return self.items[index]
  }

  init(query: QueryReference, updateHandler: @escaping (Diff<T>) -> ()) {
    self.items = []
    self.query = query
    self.listener = nil
    self.updateHandler = updateHandler
  }

  func listen() {
    self.listener = self.query.listen()
        .setSnapshotHandler { docset in
          let models = docset.documents.map { (document) -> T in
            if let model = T(dictionary: document.data()) {
              return model
            } else {
              // handle error
              fatalError("Unable to initialize type \(T.self) with dictionary \(document.data())")
            }
          }
          let diff = Diff(self.items, models)
          self.items = models
          self.documents = docset.documents
          self.updateHandler(diff)
        }
  }

  func stopListening() {
    self.listener?.stopListening()
  }
}

@objc class GlobalChatCollectionViewDataSource: NSObject, UICollectionViewDataSource {

  let localCollection: LocalCollection<Message>
  let userID: String

  var items: [Message] {
    return self.localCollection.items
  }

  public init(collection: LocalCollection<Message>, userID: String) {
    self.userID = userID
    self.localCollection = collection
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.localCollection.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GlobalChatCell",
                                                  for: indexPath) as! GlobalChatCollectionViewCell
    // self.collection must be initialized by this point, force unwrap to assert
    let message = self.localCollection[indexPath.item]

    cell.populate(message: message, isSender: userID == message.userID)
    return cell
  }

  func deleteMessage(atIndexPath indexPath: IndexPath) {
    let document = self.localCollection.documents[indexPath.item]
    document.reference.remove()
  }

}
