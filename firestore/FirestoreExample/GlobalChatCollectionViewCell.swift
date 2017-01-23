//
//  GlobalChatCollectionViewCell.swift
//  FirestoreExample
//
//  Created by Morgan Chen on 1/18/17.
//  Copyright © 2017 Morgan Chen. All rights reserved.
//

import UIKit

class GlobalChatCollectionViewCell: UICollectionViewCell {

  @IBOutlet var textLabel: UILabel! {
    didSet {
      textLabel.numberOfLines = 0
      textLabel.lineBreakMode = .byWordWrapping
      textLabel.font = GlobalChatCollectionViewCell.messageFont
    }
  }

  func populate(message: Message, isSender: Bool) {
    self.textLabel.text = message.text

    self.contentView.layer.cornerRadius = 8
    self.layer.masksToBounds = true
    let colors: (background: UIColor, text: UIColor)
    if isSender {
      colors = GlobalChatCollectionViewCell.selfColors
    } else {
      colors = GlobalChatCollectionViewCell.selfColors
    }
    self.contentView.backgroundColor = colors.background
    self.textLabel.textColor = colors.text
  }

  static var internalPadding: CGFloat {
    return 8
  }

  static func boundingRect(forText text: String, maxWidth: CGFloat) -> CGRect {
    let attributes = [NSFontAttributeName: GlobalChatCollectionViewCell.messageFont]
    var rect = text.boundingRect(with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
                                 options: [.usesLineFragmentOrigin],
                                 attributes: attributes,
                                 context: nil)
    var size = rect.size
    size.width = min(size.width + internalPadding * 2, maxWidth)
    size.height += internalPadding * 2
    rect.size = size
    return rect
  }

  static var messageFont: UIFont {
    return UIFont.systemFont(ofSize: UIFont.systemFontSize)
  }

  static var selfColors: (background: UIColor, text: UIColor) {
    return (
      background: UIColor(red: 21 / 255, green: 60 / 255, blue: 235 / 255, alpha: 1),
      text: UIColor.white
    )
  }

  static var othersColors: (background: UIColor, text: UIColor) {
    return (
      background: UIColor(red: 230 / 255, green: 230 / 255, blue: 230 / 255, alpha: 1),
      text: UIColor.black
    )
  }

}
