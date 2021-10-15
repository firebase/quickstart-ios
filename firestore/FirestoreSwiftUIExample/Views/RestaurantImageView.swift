//
//  ImageThumbnailView.swift
//  FirestoreSwiftUIExample
//
//  Copyright (c) 2021 Google Inc.
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

import SwiftUI
import SDWebImageSwiftUI

struct RestaurantImageView: View {
  var imageURL: URL
  var isThumbnail: Bool

  var body: some View {
    if isThumbnail {
      WebImage(url: imageURL)
        .resizable()
        .aspectRatio(1, contentMode: .fill)
        .frame(width: 100, height: 100, alignment: .leading)
    } else {
      WebImage(url: imageURL)
        .resizable()
        .aspectRatio(contentMode: .fill)
    }
  }
}
