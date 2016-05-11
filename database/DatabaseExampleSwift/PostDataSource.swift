//
//  PostDataSource.swift
//  DatabaseExample
//
//  Created by Ibrahim Ulukaya on 5/5/16.
//  Copyright © 2016 Google Inc. All rights reserved.
//

import UIKit
import FirebaseUI

class PostDataSource: FirebaseTableViewDataSource {

  override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
  }
  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
      refForIndex(UInt(indexPath.row)).removeValue()
    }
  }

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if self.count() != 0 {
      tableView.separatorStyle = .SingleLine
      tableView.backgroundView = nil
    }
    return self.count()
  }

  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    let noDataLabel = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
    noDataLabel.text = "No posts yet - why not add one?"
    noDataLabel.textColor = UIColor.blackColor()
    noDataLabel.textAlignment = .Center
    tableView.backgroundView = noDataLabel
    tableView.separatorStyle = .None
    return 1
  }
}
