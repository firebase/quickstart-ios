//
//  ImageThumbnailView.swift
//  FirestoreSwiftUIExample
//

import SwiftUI
import SDWebImageSwiftUI

struct ImageThumbnailView: View {
  var imageURL: URL

  var body: some View {
    WebImage(url: imageURL)
      .resizable()
      .placeholder(Image(systemName: "photo"))
      .aspectRatio(1, contentMode: .fill)
      .frame(width: 100, height: 100, alignment: .leading)
  }
}
