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

import UIKit

import FirebaseApp

@objc(DownloadViewController)
class DownloadViewController: UIViewController {

  @IBOutlet weak var imageView:UIImageView!
  @IBOutlet weak var statusTextView:UITextView!
  var storageRef:FIRStorage!

  override func viewDidLoad() {
    super.viewDidLoad()
    let app = FIRFirebaseApp.app()
    // Configure manually with a storage bucket.
    let bucket = "YOUR_PROJECT.storage.firebase.com"
    storageRef = FIRStorage.init(app: app!, bucketName: bucket)

    let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory,
        NSSearchPathDomainMask.UserDomainMask, true)
    let documentsDirectory = paths[0]
    let filePath = "file:\(documentsDirectory)/myimage.jpg"

    // [START downloadimage]
    let download: FIRStorageDownloadTask = storageRef.childByAppendingString("myimage.jpg").fileByWritingToPath(filePath)
    // [END downloadimage]

    // [START downloadcomplete]
    download.observeStatus(.Complete, withCallback: { (task) in
      self.statusTextView.text = "Download Succeeded!"
      self.onSuccesfulDownload(filePath)
    })
    // [END downloadcomplete]

    // [START downloadfailure]
    download.observeStatus(.Failure) { (task, error) in
      if let error = error {
        print("Error downloading:\(error)")
      }
      self.statusTextView.text = "Download Failed"
    }
    // [END downloadfailure]
  }

  func onSuccesfulDownload(filePath: String) {
    imageView.image = UIImage.init(contentsOfFile: filePath)
  }
}
