//
//  Message.swift
//  FirestoreExample
//
//  Created by Morgan Chen on 1/17/17.
//  Copyright © 2017 Morgan Chen. All rights reserved.
//

import Foundation

// A type that can be initialized from a Firestore document.
protocol DocumentSerializable {
  init?(dictionary: [String: Any])
}

struct Message: DocumentSerializable, Hashable {
  var userID: String
  var name: String
  var text: String
  var timestamp: Date

  init(userID: String, name: String, text: String, timestamp: Date) {
    self.userID = userID; self.name = name; self.text = text; self.timestamp = timestamp
  }

  init?(dictionary: [String: Any]) {
    guard let uid = dictionary["userID"] as? String,
        let name = dictionary["name"] as? String,
        let text = dictionary["text"] as? String,
        let timestamp = dictionary["timestamp"] as? Date else {
          return nil
    }
    self.userID = uid
    self.name = name
    self.text = text
    self.timestamp = timestamp
  }

  public static func ==(lhs: Message, rhs: Message) -> Bool {
    return lhs.userID == rhs.userID && lhs.name == rhs.name && lhs.text == rhs.text
        && lhs.timestamp == rhs.timestamp
  }

  var hashValue: Int {
    return self.userID.hashValue ^ self.text.hashValue
        ^ self.name.hashValue ^ self.timestamp.hashValue
  }

  var dictionary: [String: Any] {
    return [
      "userID":    self.userID,
      "name":      self.name,
      "text":      self.text,
      "timestamp": self.timestamp,
    ]
  }
}
