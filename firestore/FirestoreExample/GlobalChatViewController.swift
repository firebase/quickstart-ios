//
//  GlobalChatViewController.swift
//  FirestoreExample
//
//  Created by Morgan Chen on 1/17/17.
//  Copyright © 2017 Morgan Chen. All rights reserved.
//

import UIKit

import Firestore

import FirebaseAuth
import FirebaseAuthUI

class GlobalChatViewController: UIViewController {

  var auth: FUIAuth! = nil
  var user: FIRUser? = nil
  var collection: CollectionReference?
  var query: QueryReference?

  var dataSource: GlobalChatCollectionViewDataSource!

  var localCollection: LocalCollection<Message>? = nil

  @IBOutlet private var collectionView: UICollectionView!
  @IBOutlet var textView: UITextView! {
    didSet {
      textView.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
      textView.layer.borderWidth = 1
      textView.layer.cornerRadius = 8
      textView.layer.masksToBounds = true
    }
  }
  @IBOutlet var sendButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.auth = FUIAuth.defaultAuthUI()
    self.collectionView.dataSource = nil
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if let user = self.auth.auth?.currentUser {
      self.user = user

      let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")!
      let googleServicePlist = NSDictionary(contentsOfFile: plistPath)!
      let projectID = googleServicePlist["PROJECT_ID"] as! String
      let store = Firestore(projectID: projectID)
      let collection = store.collection(name: "messages")
      let query = collection.queryOrdered(byField: "timestamp")
      self.collection = collection
      self.query = query

      let localCollection = LocalCollection<Message>(query: query) { diff in
        // animated updates to collectionview go here
        self.collectionView.performBatchUpdates({
          func indexPathFromDiffPair(_ diffPair: (Any, Int)) -> IndexPath {
            return IndexPath(row: diffPair.1, section: 0)
          }

          let deletedIndexPaths = diff.deleted.map(indexPathFromDiffPair)
          self.collectionView.deleteItems(at: deletedIndexPaths)

          let insertedIndexPaths = diff.inserted.map(indexPathFromDiffPair)
          self.collectionView.insertItems(at: insertedIndexPaths)
        }, completion: nil)
      }
      localCollection.listen()
      self.dataSource = GlobalChatCollectionViewDataSource(collection: localCollection,
                                                           userID: user.uid)
      self.collectionView.dataSource = self.dataSource
      self.collectionView.collectionViewLayout = GlobalChatLayout(dataSource: self.dataSource,
                                                                  userID: user.uid)
      self.localCollection = localCollection
    } else {
      let authController = self.auth.authViewController()
      self.present(authController, animated: true, completion: nil)
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    self.localCollection?.stopListening()
  }

  @IBAction private func didTapSend(_ sender: Any) {
    guard let user = self.user else { return }
    guard let collection = self.collection else { return }
    guard let text = self.textView.text?
      .trimmingCharacters(in: .whitespacesAndNewlines) else { return }
    guard !text.isEmpty else { return }

    let message = Message(
      userID: user.uid,
      name: user.displayName ?? "Anonymous",
      text: text,
      timestamp: Date()
    ).dictionary

    collection.addDocument(withData: message)
    self.textView.text = ""
  }

  @IBAction func didLongPress(_ sender: Any) {
    guard let gestureRecognizer = sender as? UILongPressGestureRecognizer else { return }
    guard let indexPath = self.collectionView
      .indexPathForItem(at: gestureRecognizer.location(in: self.collectionView)) else { return }

    // Action sheet pop-up here is best, since deletes shouldn't be accidental or surprising.
    self.dataSource.deleteMessage(atIndexPath: indexPath)
    gestureRecognizer.isEnabled = false
    gestureRecognizer.isEnabled = true
  }
}

