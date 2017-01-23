//
//  GlobalChatLayout.swift
//  FirestoreExample
//
//  Created by Morgan Chen on 1/20/17.
//  Copyright © 2017 Morgan Chen. All rights reserved.
//

import UIKit

class GlobalChatLayout: UICollectionViewLayout {

  let dataSource: GlobalChatCollectionViewDataSource
  let userID: String

  private var internalWidth: CGFloat {
    guard let view = self.collectionView else { return 0 }
    return view.bounds.size.width - (GlobalChatLayout.internalPadding * 2)
  }

  private var maxCellWidth: CGFloat {
    return self.internalWidth * 0.75
  }

  static var internalPadding: CGFloat {
    return 8
  }

  static var paddingBetweenCells: CGFloat {
    return 8
  }

  public init(dataSource: GlobalChatCollectionViewDataSource, userID: String) {
    self.dataSource = dataSource
    self.userID = userID
    super.init()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func rect(forCellAtIndexPath indexPath: IndexPath) -> CGRect {
    let maxWidth = self.maxCellWidth
    let message = self.dataSource.items[indexPath.item]
    let size = GlobalChatCollectionViewCell.boundingRect(forText: message.text,
                                                         maxWidth: maxWidth).size

    var offset: CGFloat = GlobalChatLayout.paddingBetweenCells

    for index in self.dataSource.items.indices {
      if index >= indexPath.item { break }
      let element = self.dataSource.items[index]
      offset += GlobalChatCollectionViewCell.boundingRect(forText: element.text,
                                                          maxWidth: maxWidth).size.height
      offset += GlobalChatLayout.paddingBetweenCells
    }

    let align = message.userID == self.userID ?
      self.internalWidth - size.width : GlobalChatLayout.internalPadding

    let rect = CGRect(origin: CGPoint(x: align, y: offset), size: size)
    return rect
  }

  override var collectionViewContentSize: CGSize {
    guard let view = self.collectionView else { return CGSize.zero }
    let padding = GlobalChatLayout.paddingBetweenCells

    let width = self.maxCellWidth
    let height = self.dataSource.items.reduce(padding) { (aggregate, next) -> CGFloat in
      let bounds = GlobalChatCollectionViewCell.boundingRect(forText: next.text,
                                                             maxWidth: width)
      return aggregate + bounds.size.height + padding
    }
    let size = CGSize(width: view.frame.size.width, height: height)
    return size
  }

  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
    attributes.frame = self.rect(forCellAtIndexPath: indexPath)
    return attributes
  }

  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    var attributes: [UICollectionViewLayoutAttributes] = []
    for index in 0..<self.dataSource.items.count {
      let indexPath = IndexPath(item: index, section: 0)
      let messageRect = self.rect(forCellAtIndexPath: indexPath)
      if rect.intersects(messageRect) {
        attributes.append(self.layoutAttributesForItem(at: indexPath)!)
      }
    }
    return attributes
  }

  override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    return newBounds.size.width != self.collectionView!.bounds.size.width
  }

}
