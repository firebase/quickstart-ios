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
import FirebaseStorage
import Firebase

@objc(DownloadViewController)
class DownloadViewController: UIViewController {

  @IBOutlet weak var imageView:UIImageView!
  @IBOutlet weak var statusTextView:UITextView!
  var storageRef:FIRStorageReference!

  override func viewDidLoad() {
    super.viewDidLoad()
    storageRef = FIRStorage.storage().reference()

    let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory,
        NSSearchPathDomainMask.UserDomainMask, true)
    let documentsDirectory = paths[0]
    let filePath = "file:\(documentsDirectory)/myimage.jpg"
    let storagePath = NSUserDefaults.standardUserDefaults().objectForKey("storagePath") as! String

    // [START downloadimage]
    storageRef.child(storagePath).writeToFile(NSURL.fileURLWithPath(filePath),
                                              completion: { (url, error) in
      if let error = error {
        print("Error downloading:\(error)")
        self.statusTextView.text = "Download Failed"
        return
      }
      self.statusTextView.text = "Download Succeeded!"
      self.imageView.image = UIImage.init(contentsOfFile: filePath)
    })
    // [END downloadimage]
  }
}
