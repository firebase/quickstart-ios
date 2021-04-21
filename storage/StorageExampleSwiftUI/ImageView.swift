// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftUI
import Firebase

/// ImageView provides the main content for the app. It displays a current image and provides
/// controls to change it by taking a new one with the camera, selecting one from the photo library
/// or downloading one from Firebase storage.
struct ImageView: View {
  /// Manages retrieval and persistence of the current image.
  @StateObject private var photoStore = ImageStore(storage: Storage.storage())

  /// Indicates whether the user is selecting an image from the photo library.
  @State var isSelectingImage = false

  /// Indicates whether the user is taking an image using the camera.
  @State var isTakingPhoto = false

  /// Indicates whether a submenu that allows the user to choose whether to select or take a photo
  /// should be visible.
  @State var showUploadMenu = false

  var body: some View {
    NavigationView {
      VStack {
        Image(uiImage: photoStore.image ?? UIImage())
          .resizable()
          .aspectRatio(contentMode: .fit)
      }
      .navigationTitle("Firebase Storage")
      .toolbar {
        ToolbarItemGroup(placement: .bottomBar) {
          if showUploadMenu {
            Button("❌") {
              showUploadMenu = false
            }

            Spacer()

            Button("Take Photo") {
              isTakingPhoto = true
            }.sheet(isPresented: $isTakingPhoto) {
              ImagePickerRepresentable(
                source: .camera,
                store: photoStore,
                visible: $isTakingPhoto
              ) {
                showUploadMenu = false
              }
            }.disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

            Button("Select Image") {
              isSelectingImage = true
            }.sheet(isPresented: $isSelectingImage) {
              ImagePickerRepresentable(
                source: .photoLibrary,
                store: photoStore,
                visible: $isSelectingImage
              ) {
                showUploadMenu = false
              }
            }
          } else {
            Button("Upload") {
              showUploadMenu = true
            }
            Spacer()
            Button("Download") {
              photoStore.loadImage()
            }
          }
        }
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ImageView()
  }
}
