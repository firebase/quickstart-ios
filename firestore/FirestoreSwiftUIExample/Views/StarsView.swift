//
//  StarsView.swift
//  FirestoreSwiftUIExample
//

import SwiftUI

struct StarsView: View {
  var rating: Int

  var body: some View {
    HStack {
      ForEach(1..<6) { i in
        getStar(num: i, rating: rating)
          .frame(width: 12, height: 20)
          .foregroundColor(getStarColor(num: i, rating: rating))
      }
    }
  }

  func getStar(num: Int, rating: Int) -> Image {
    num > rating ? Image(systemName: "star") : Image(systemName: "star.fill")
  }

  func getStarColor(num: Int, rating: Int) -> Color {
    num > rating ? Color.gray : Color.yellow
  }
}

struct StarsView_Previews: PreviewProvider {
  static var previews: some View {
    StarsView(rating: 3)
  }
}
