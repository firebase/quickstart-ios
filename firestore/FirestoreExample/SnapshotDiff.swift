//
//  SnapshotDiff.swift
//  FirestoreExample
//
//  Created by Morgan Chen on 1/18/17.
//  Copyright © 2017 Morgan Chen. All rights reserved.
//

import Foundation

// This entire file exists so we can use UICollectionView's performBatchUpdates
// with snapshots from Firestore. Should probably file a bug

fileprivate extension ArraySlice where Element: Hashable {
  var hashValue: Int {
    return self.reduce(5381) { (initial, next) -> Int in
      return (initial << 5) &+ initial &+ next.hashValue
    }
  }
}

fileprivate struct HashableSlice<T: Hashable>: Hashable {
  var slice: ArraySlice<T>

  init(_ slice: ArraySlice<T>) {
    self.slice = slice
  }

  public static func ==<T>(lhs: HashableSlice<T>, rhs: HashableSlice<T>) -> Bool {
    return lhs.slice == rhs.slice
  }

  var hashValue: Int {
    return self.slice.hashValue
  }
}

fileprivate struct UnorderedHashablePair<T: Hashable>: Hashable {
  var left, right: T

  public var hashValue: Int {
    return left.hashValue ^ right.hashValue
  }

  public static func ==<T>(lhs: UnorderedHashablePair<T>, rhs: UnorderedHashablePair<T>) -> Bool {
    // Pairs must be equal if they contain the same two elements regardless of order.
    return (lhs.left == rhs.left && lhs.right == rhs.right) ||
      (lhs.right == rhs.left && lhs.left == rhs.right)
  }

  public init(_ lhs: T, _ rhs: T) {
    self.left = lhs; self.right = rhs
  }
}

fileprivate struct _LCS<T: Hashable> {
  private var memo: [UnorderedHashablePair<HashableSlice<T>>: ArraySlice<T>] = [:]

  mutating func lcs(_ lhs: ArraySlice<T>, _ rhs: ArraySlice<T>) -> ArraySlice<T> {
    if lhs.count == 0 || rhs.count == 0 { return ArraySlice<T>() }

    // check memo
    let arguments = UnorderedHashablePair(HashableSlice(lhs), HashableSlice(rhs))
    if let memoized = memo[arguments] {
      return memoized
    }

    var aggregate = ArraySlice<T>()

    let shorter: ArraySlice<T>
    let longer: ArraySlice<T>
    let lhsIsShorter = lhs.count <= rhs.count
    if lhsIsShorter {
      shorter = lhs; longer = rhs
    } else {
      longer = lhs; shorter = rhs
    }

    // Aggregate common elements.
    let shortOffset = shorter.startIndex
    let longOffset  = longer.startIndex
    for i in 0..<shorter.count {
      if shorter[i + shortOffset] == longer[i + longOffset] {
        aggregate.append(shorter[i + shortOffset])
      } else {
        break
      }
    }

    // LCS is the entire shorter collection.
    if aggregate.count == shorter.count {
      self.memo[arguments] = aggregate
      return aggregate
    }


    // Reached uncommon element, so try LCS of both sides minus the uncommon element
    // and any previously aggregated common elements.
    let left = self.lcs(shorter.suffix(from: shortOffset + aggregate.count + 1),
                        longer.suffix(from: longOffset + aggregate.count))
    let right = self.lcs(shorter.suffix(from: shortOffset + aggregate.count),
                         longer.suffix(from: longOffset + aggregate.count + 1))


    // Return the aggregate plus the greater of the two subsequences.
    if left.count > right.count {
      aggregate += left
    } else {
      aggregate += right
    }

    self.memo[arguments] = aggregate
    return aggregate
  }
}

func LCS<T: Hashable>(_ left: [T], _ right: [T]) -> [T] {
  var memo = _LCS<T>()
  let lhs = ArraySlice(left); let rhs = ArraySlice(right)
  return Array(memo.lcs(lhs, rhs))
}

struct Diff<T> {
  var deleted: [(T, Int)]
  var inserted: [(T, Int)]
}

extension Diff where T: Hashable {

  /// All deletions happen before insertions. Returns arrays of pairs of items and indices.
  /// Insertions happen from left to right in the returned array.
  init(_ left: [T], _ right: [T]) {
    let lcs = LCS(left, right)

    var deleted: [(T, Int)] = []
    var inserted: [(T, Int)] = []

    var lcsCopy = lcs

    for i in left.indices {
      let element = left[i]
      if element == lcsCopy.first {
        lcsCopy.remove(at: 0)
      } else {
        deleted.append((element, i))
      }
    }

    lcsCopy = lcs

    for i in right.indices {
      let element = right[i]
      if element == lcsCopy.first {
        lcsCopy.remove(at: 0)
      } else {
        inserted.append((element, i))
      }
    }

    self.deleted = deleted
    self.inserted = inserted
  }
}
