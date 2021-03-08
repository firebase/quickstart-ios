//
//  PriceView.swift
//  FirestoreSwiftUIExample
//

import SwiftUI

struct PriceView: View {
  var price: Int

  var body: some View {
    Text(priceString(from: price))
      .font(.footnote)
      .foregroundColor(Color.gray)
      .multilineTextAlignment(.trailing)
  }

  func priceString(from price: Int) -> String {
    let priceText: String
    switch price {
    case 1:
      priceText = "$"
    case 2:
      priceText = "$$"
    case 3:
      priceText = "$$$"
    case _:
      fatalError("price must be between one and three")
    }

    return priceText
  }
}
