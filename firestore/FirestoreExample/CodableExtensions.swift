/*
 * Copyright 2019 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import FirebaseFirestore
import FirebaseFirestoreSwift

private func encodeOrDie<T: Encodable>(_ value: T) -> [String: Any] {
  do {
    return try Firestore.Encoder().encode(value)
  } catch let error {
    fatalError("Unable to encode data with Firestore encoder: \(error)")
  }
}

extension CollectionReference {
  public func addDocument<T: Encodable>(from encodable: T) -> DocumentReference {
    let encoded = encodeOrDie(encodable)
    return addDocument(data: encoded)
  }

  public func addDocument<T: Encodable>(from encodable: T, _ completion: ((Error?) -> Void)?) -> DocumentReference {
    let encoded = encodeOrDie(encodable)
    return addDocument(data: encoded, completion: completion)
  }
}

extension DocumentReference {
  public func setData<T: Encodable>(from encodable: T) {
    let encoded = encodeOrDie(encodable)
    setData(encoded)
  }

  public func setData<T: Encodable>(from encodable: T, _ completion: ((Error?) -> Void)?) {
    let encoded = encodeOrDie(encodable)
    setData(encoded, completion: completion)
  }
}

extension DocumentSnapshot {
  public func data<T: Decodable>(as type: T.Type) throws -> T {
    guard let dict = data() else {
      throw DecodingError.valueNotFound(T.self,
                                        DecodingError.Context(codingPath: [],
                                                              debugDescription: "Data was empty"))
    }
    return try Firestore.Decoder().decode(T.self, from: dict)
  }
}

extension Transaction {
  public func setData<T: Encodable>(from encodable: T, forDocument: DocumentReference) {
    let encoded = encodeOrDie(encodable)
    setData(encoded, forDocument: forDocument)
  }
}

extension WriteBatch {
  public func setData<T: Encodable>(from encodable: T, forDocument: DocumentReference) {
    let encoded = encodeOrDie(encodable)
    setData(encoded, forDocument: forDocument)
  }
}
