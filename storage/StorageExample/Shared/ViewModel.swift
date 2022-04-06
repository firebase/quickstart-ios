//
//  Copyright (c) 2022 Google Inc.
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

import Foundation
import SwiftUI
#if !os(macOS)
  import UIKit
#endif

@MainActor
class ViewModel: ObservableObject {
  @Published var image: Image?
  @Published var showingImagePicker = false
  #if os(iOS) || os(tvOS)
    @Published var inputImage: UIImage?
  #elseif os(macOS)
    @Published var inputImage: NSImage?
  #endif
  @Published var downloadPicButtonEnabled: Bool = false
  @Published var downloadDone: Bool = false
  @Published var downloadedImage: Image?
  @Published var errorFound: Bool = false
  @Published var errInfo: Error?
  @Published var fileUploaded: Bool = false
  @Published var fileDownloadURL: URL?
  @Published var fileLocalDownloadURL: URL?
  @Published var isLoading: Bool = false
  @Published var remoteStoragePath: String?
  #if os(tvOS)
    // The app for tvOS will check if `remoteStoragePathForSearch` exists to
    // determine if an image should be downloaded and displayed.
    @Published var remoteStoragePathForSearch: String = ""
  #endif
}
