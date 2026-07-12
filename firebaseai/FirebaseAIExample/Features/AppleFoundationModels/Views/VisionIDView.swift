// Copyright 2026 Google LLC
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

#if canImport(FoundationModels)
import SwiftUI
import PhotosUI

@available(iOS 27.0, *)
@MainActor
struct VisionIDView: View {
  @ObservedObject var viewModel: VisionIDViewModel
  @Binding var photosPickerItem: PhotosPickerItem?

  @MainActor
  var body: some View {
    let selectedImage = viewModel.selectedImage

    VStack(alignment: .leading, spacing: 16) {
      Text("Select or Snap a Photo to Identify")
        .font(.headline)

      PhotosPicker(selection: $photosPickerItem, matching: .images) {
        VStack(spacing: 12) {
          if let image = selectedImage {
            Image(uiImage: image)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(maxHeight: 200)
              .cornerRadius(12)
          } else {
            VStack(spacing: 8) {
              Image(systemName: "photo.badge.plus")
                .font(.system(size: 40))
              Text("Select an Image")
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
          }
        }
      }
      .onChange(of: photosPickerItem) { oldItem, newItem in
        Task {
          if let data = try? await newItem?.loadTransferable(type: Data.self),
            let image = UIImage(data: data) {
            viewModel.selectedImage = image
            viewModel.identifySelectedImage()
          }
        }
      }

      if let identified = viewModel.identifiedObject {
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            Text("Identification Result")
              .font(.headline)
            Spacer()
            ModelIndicatorView(isUsingLocalModel: viewModel.isUsingLocalModel)
          }

          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Text("Name:")
                .bold()
              Text(identified.name)
            }
            HStack {
              Text("Category:")
                .bold()
              Text(identified.category)
            }
            VStack(alignment: .leading, spacing: 4) {
              Text("Description:")
                .bold()
              Text(identified.description)
                .foregroundColor(.secondary)
            }
          }
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color(.secondarySystemGroupedBackground))
          .cornerRadius(10)
        }
        .transition(.opacity)
      }
    }
  }
}
#endif
