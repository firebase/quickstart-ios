//
//  PostTableTableViewCell.swift
//  DatabaseExample
//
//  Created by Ibrahim Ulukaya on 5/5/16.
//  Copyright © 2016 Google Inc. All rights reserved.
//

import UIKit

class PostTableViewCell: UITableViewCell {
  @IBOutlet weak var authorImage: UIImageView!
  @IBOutlet weak var authorLabel: UILabel!
  @IBOutlet weak var starImage: UIImageView!
  @IBOutlet weak var numStarsLabel: UILabel!
  @IBOutlet weak var postTitle: UILabel!
  @IBOutlet weak var postBody: UITextView!

}
