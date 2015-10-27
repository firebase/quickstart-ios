//
//  Copyright (c) 2015 Google Inc.
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
/* Note that "import Firebase" is included in BridgingHeader.h */

@objc(ViewController)
class ViewController: UIViewController {
  
  var ref: Firebase!
  private var _refHandle: FirebaseHandle!

  override func viewDidLoad() {
    super.viewDidLoad()
    if let plist = NSDictionary(contentsOfFile: NSBundle.mainBundle().pathForResource("Info", ofType: "plist")!) {
      self.ref = Firebase(url: plist["kFirebaseUrl"] as! String)
    }
  }
  
  override func viewWillAppear(animated: Bool) {
    _refHandle = self.ref.observeEventType(.ChildAdded, withBlock: { (snapshot) -> Void in
      // Populate view here
    })
  }
  
  override func viewWillDisappear(animated: Bool) {
    self.ref.removeObserverWithHandle(_refHandle)
  }

}
