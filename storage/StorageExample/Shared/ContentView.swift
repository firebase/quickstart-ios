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

import SwiftUI
import FirebaseAuth
import FirebaseStorage

struct ContentView: View {
  @EnvironmentObject var viewModel: ViewModel
  @State private var authenticated: Bool = true
  private var storage = Storage.storage()
  private var imageURL: URL = FileManager.default.temporaryDirectory
    .appendingPathComponent("tempImage.jpeg")

  var body: some View {
    ZStack {
      VStack {
        #if os(iOS)
          if let image = viewModel.image {
            image
              .resizable()
              .scaledToFit()
              .frame(minWidth: 300, maxHeight: 200)
              .cornerRadius(16)

          } else {
            Image(systemName: "photo.fill")
              .resizable()
              .scaledToFit()
              .opacity(0.6)
              .frame(width: 300, height: 200, alignment: .top)
              .cornerRadius(16)
              .padding(.horizontal)
          }
          Button("Photo") {
            viewModel.showingImagePicker = true
          }
          .buttonStyle(OrangeButton())
          .disabled(!authenticated)
        #elseif os(macOS)
          ImagePicker(image: $viewModel.inputImage, imageURL: imageURL)
        #elseif os(tvOS)
          TextField("Upload an Image to Storage and type the path here.",
                    text: $viewModel.remoteStoragePathForSearch)
            .onSubmit {
              let filePath = viewModel.remoteStoragePathForSearch
              let storageRef = storage.reference(withPath: filePath)
              fetchDownloadURL(storageRef, storagePath: filePath)
            }
        #endif
        if viewModel.image != nil {
          Button("Upload from Data") {
            uploadFromData()
          }
          .buttonStyle(OrangeButton())
        }

        if viewModel.image != nil, FileManager.default.fileExists(atPath: imageURL.path) {
          Button("Upload from URL") {
            uploadFromALocalFile()
          }
          .buttonStyle(OrangeButton())
        }
        if viewModel.downloadPicButtonEnabled {
          Button("Download") {
            Task {
              await downloadImage()
            }
          }
          .buttonStyle(OrangeButton())
        }
      }
      #if os(iOS)
        .sheet(isPresented: $viewModel.showingImagePicker) {
          ImagePicker(image: $viewModel.inputImage, imageURL: imageURL)
        }
      #endif
      .sheet(isPresented: $viewModel.downloadDone) {
        if let image = viewModel.downloadedImage {
          VStack {
            image
              .resizable()
              .scaledToFit()
              .frame(minWidth: 0, maxWidth: .infinity)
          }
          #if !os(tvOS)
            .onTapGesture {
              viewModel.downloadDone = false
            }
          #endif
          #if os(macOS)
            Button {
              NSWorkspace.shared.selectFile(
                viewModel.fileLocalDownloadURL!.path,
                inFileViewerRootedAtPath: ""
              )
            } label: {
              Text("Open in Finder")
            }
            .buttonStyle(OrangeButton())
          #endif
        }
      }
      .onChange(of: viewModel.inputImage) { _ in
        loadImage()
      }
      .task {
        await signInAnonymously()
      }
      .alert("Error", isPresented: $viewModel.errorFound) {
        Button("ok") { viewModel.errorFound = false }
      } message: {
        if let errInfo = viewModel.errInfo {
          Text(errInfo.localizedDescription)
        } else {
          Text("No error discription is found.")
        }
      }
      .alert("Image was uploaded", isPresented: $viewModel.fileUploaded) {
        Button("ok") {}
        Button("Link") {
          if let url = viewModel.fileDownloadURL {
            print("downloaded url: \(url)")
            #if os(iOS)
              UIApplication.shared.open(url)
            #elseif os(macOS)
              NSWorkspace.shared.open(url)
            #endif
          }
        }
      }

      if viewModel.isLoading {
        LoadingView()
      }
    }
    #if os(macOS)
      .frame(width: 300, height: 600)
    #endif
  }

  func loadImage() {
    guard let inputImage = viewModel.inputImage else {
      return
    }
    viewModel.image = setImage(fromImage: inputImage)
    viewModel.showingImagePicker = false
  }

  func uploadFromALocalFile() {
    let filePath = Auth.auth().currentUser!.uid +
      "/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\(imageURL.lastPathComponent)"
    let storageRef = storage.reference(withPath: filePath)

    viewModel.isLoading = true
    storageRef.putFile(from: imageURL, metadata: nil) { metadata, error in
      guard let _ = metadata else {
        // Uh-oh, an error occurred!
        viewModel.errorFound = true
        viewModel.errInfo = error
        return
      }

      viewModel.isLoading = false
      // You can also access to download URL after upload.
      fetchDownloadURL(storageRef, storagePath: filePath)
    }
  }

  func uploadFromData() {
    guard let imageData = viewModel.inputImage?.jpeg else {
      print("The image from url \(imageURL.path) cannot be transferred to data.")
      return
    }
    let filePath = Auth.auth().currentUser!.uid +
      "/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/fromData/\(imageURL.lastPathComponent)"
    let storageRef = storage.reference(withPath: filePath)

    viewModel.isLoading = true
    storageRef.putData(imageData, metadata: nil) { metadata, error in
      guard let _ = metadata else {
        // Uh-oh, an error occurred!
        viewModel.errorFound = true
        viewModel.errInfo = error
        return
      }
      viewModel.isLoading = false
      // You can also access to download URL after upload.
      fetchDownloadURL(storageRef, storagePath: filePath)
    }
  }

  func fetchDownloadURL(_ storageRef: StorageReference, storagePath: String) {
    storageRef.downloadURL { url, error in

      guard let downloadURL = url else {
        print("Error getting download URL: \(error.debugDescription)")
        viewModel.errorFound = true
        viewModel.errInfo = error
        return
      }
      print("download url: \(downloadURL) ")
      viewModel.remoteStoragePath = storagePath
      viewModel.downloadPicButtonEnabled = true
      // tvOS Quickstart does not have `Upload` feature.
      #if !os(tvOS)
        viewModel.fileUploaded = true
      #endif
      viewModel.fileDownloadURL = downloadURL
    }
  }

  func downloadImage() async {
    // Create a reference to the file you want to download
    let storageRef = Storage.storage().reference()

    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    let documentsDirectory = paths[0]
    let filePath = "file:\(documentsDirectory)/myimage.jpg"
    guard let fileURL = URL(string: filePath) else { return }
    guard let storagePath = viewModel.remoteStoragePath else {
      return
    }

    viewModel.isLoading = true
    do {
      let imageURL = try await storageRef.child(storagePath).writeAsync(toFile: fileURL)
      viewModel.downloadDone = true
      viewModel.downloadedImage = setImage(fromURL: imageURL)
      viewModel.fileLocalDownloadURL = imageURL
    } catch {
      viewModel.errorFound = true
      viewModel.errInfo = error
    }
    viewModel.isLoading = false
  }

  func signInAnonymously() async {
    // Using Cloud Storage for Firebase requires the user be authenticated. Here we are using
    // anonymous authentication.
    if Auth.auth().currentUser == nil {
      do {
        try await Auth.auth().signInAnonymously()
        authenticated = true
      } catch {
        print("Not able to connect: \(error)")
        Task { @MainActor in
          viewModel.errorFound = true
          viewModel.errInfo = error
        }
        authenticated = false
      }
    }
  }

  #if os(iOS) || os(tvOS)
    func setImage(fromImage image: UIImage) -> Image {
      return Image(uiImage: image)
    }

  #elseif os(macOS)
    func setImage(fromImage image: NSImage) -> Image {
      return Image(nsImage: image)
    }
  #endif
  func setImage(fromURL url: URL) -> Image {
    return setImage(fromImage: .init(contentsOfFile: url.path)!)
  }
}

struct OrangeButton: ButtonStyle {
  @Environment(\.isEnabled) private var isEnabled: Bool
  #if os(tvOS)
    @Environment(\.isFocused) var focused: Bool
  #endif

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding()
      .background(isEnabled ? Color.orange : Color.orange.opacity(0.5))
      .foregroundColor(.white)
      .clipShape(RoundedRectangle(cornerRadius: 16.0))
    #if os(tvOS)
      .scaleEffect(focused ? 1.2 : 1)
      .animation(.easeIn, value: focused)
    #endif
  }
}

#if os(iOS) || os(tvOS)
  extension UIImage {
    var jpeg: Data? {
      jpegData(compressionQuality: 1)
    }
  }

#elseif os(macOS)
  extension NSImage {
    var jpeg: Data? {
      let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil)!
      let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
      return bitmapRep.representation(
        using: NSBitmapImageRep.FileType.jpeg,
        properties: [:]
      )
    }
  }
#endif

struct LoadingView: View {
  var body: some View {
    ZStack {
      Color(.gray)
        .ignoresSafeArea()
        .opacity(0.5)
      ProgressView()
        .progressViewStyle(CircularProgressViewStyle(tint: .orange))
        .scaleEffect(3)
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
