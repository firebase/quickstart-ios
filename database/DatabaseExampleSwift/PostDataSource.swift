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
import FirebaseDatabaseUI

class PostDataSource: FirebaseTableViewDataSource {

  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      ref(for: UInt((indexPath as NSIndexPath).row)).removeValue()
    }
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if self.count != 0 {
      tableView.separatorStyle = .singleLine
      tableView.backgroundView = nil
    }
    return Int(self.count)
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    let noDataLabel = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
    noDataLabel.text = "No posts yet - why not add one?"
    noDataLabel.textColor = UIColor.black
    noDataLabel.textAlignment = .center
    tableView.backgroundView = noDataLabel
    tableView.separatorStyle = .none
    return 1
  }
}
