//
//  RestaurantListViewModel.swift
//  FirestoreSwiftUIExample
//

import Combine
import Firebase

class RestaurantListViewModel: ObservableObject {

  @Published var restaurants = [Restaurant]()
  private var db = Firestore.firestore()
  private var listener: ListenerRegistration?

  deinit {
    unsubscribe()
  }

  func unsubscribe() {
    if listener != nil {
      listener?.remove()
      listener = nil
    }
  }

  func subscribe() {
    if listener == nil {
      listener = db.collection("restaurants").addSnapshotListener { [weak self] (querySnapshot, error) in
        guard let documents = querySnapshot?.documents else {
          print("Error fetching documents: \(error!)")
          return
        }

        guard let self = self else { return }
        self.restaurants = documents.compactMap { document in
          do {
            return try document.data(as: Restaurant.self)
          } catch let error {
            print(error)
            return nil
          }
        }
      }
    }
  }

  func populate() {
    db.populate()
  }
}
