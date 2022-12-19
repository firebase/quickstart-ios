// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import FirebaseFirestore
import FirebaseFirestoreSwift
import Gzip
import SwiftUI

struct FirestoreBlobView: View {
  @State private var showingAlert = false
  @State private var alert = Alert(title: Text(""))

  var body: some View {
    VStack(spacing: 20.0) {
      Button("Insert Blob") {
        insertBlob()
      }.alert(isPresented: $showingAlert) {
        alert
      }
    }.navigationTitle("Firestore Blob Tester")
  }

  private func insertBlob() {
    let db = Firestore.firestore()

    // creates a test document with a CSV string and the corresponding Data and gzipped Data
    let csvString =
      "fruit,\nbanana,yellow,round\n,fruit,orange,orange,round\nfruit,\napple,red,round"
    let csvData = csvString.data(using: .utf8)!
    let csvZipped: Data
    do {
      csvZipped = try csvData.gzipped()
    } catch {
      alert = Alert(
        title: Text("GZip Error"),
        message: Text(error.localizedDescription)
      )
      showingAlert = true
      return
    }

    let document =
      TestDocument(csvString: csvString, csvData: csvData, csvZipped: csvZipped)

    // store the Document in Firestore
    let documentID = UUID().uuidString
    let firestoreEncoder = Firestore.Encoder()
    let documentData: [String: Any]
    do {
      documentData = try firestoreEncoder.encode(document)
    } catch {
      alert = Alert(
        title: Text("Encoding Error"),
        message: Text(error.localizedDescription)
      )
      showingAlert = true
      return
    }

    db.collection("tests").document(documentID).setData(documentData) { error in
      if let error = error {
        print("Error inserting the document: \(error.localizedDescription)")
        alert = Alert(
          title: Text("Document Insertion Error"),
          message: Text(error.localizedDescription)
        )
      } else {
        print("Document inserted successfully")
        alert = Alert(title: Text("Document Inserted Successfully"))
      }
      showingAlert = true
    }
  }
}

struct FirestoreBlobView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      FirestoreBlobView()
    }
  }
}

// The test document
private struct TestDocument: Codable {
  @DocumentID var id: String?
  @ServerTimestamp var timestamp: Timestamp?
  let csvString: String
  let csvData: Data
  let csvZipped: Data
}
