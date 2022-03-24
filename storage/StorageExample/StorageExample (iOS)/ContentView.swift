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
  @EnvironmentObject var vm: ViewModel
  @State private var authenticated: Bool = true
  private var storage = Storage.storage()
  private var imageURL: URL = FileManager.default.temporaryDirectory.appendingPathComponent("tempImage.jpeg")
  
  var body: some View {
    ZStack{
      VStack{
        if let image = vm.image{
          image
            .resizable()
            .scaledToFit()
            .frame(minWidth: 300,maxHeight: 200)
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
        Button("Photo"){
          vm.showingImagePicker = true
        }
        .buttonStyle(OrangeButton())
        .disabled(!authenticated)
        if vm.image != nil {
          Button("Upload from Data"){
            uploadFromData()
          }
          .buttonStyle(OrangeButton())
        }
        
        if let _ = vm.image, FileManager.default.fileExists(atPath: imageURL.path) {
          Button("Upload from URL"){
            uploadFromALocalFile()
          }
          .buttonStyle(OrangeButton())
          
        }
        if vm.downloadPicButtonEnabled {
          Button("Download"){
            download()
          }
          .buttonStyle(OrangeButton())
        }
      }
      .sheet(isPresented: $vm.showingImagePicker){
        ImagePicker(image: $vm.inputImage, imageURL: imageURL)
      }
      .sheet(isPresented: $vm.downloadDone){
        if let image = vm.downloadedImage{
          image
            .resizable()
            .scaledToFit()
            .frame(minWidth: 0, maxWidth: .infinity)
        }
      }
      .onChange(of: vm.inputImage) { _ in
        loadImage()
      }
      .onAppear{
        firebaseAuth()
      }
      .alert("Error", isPresented: $vm.errorFound) {
        Text(vm.errInfo.debugDescription)
        Button("ok"){}
      }
      .alert("Image was uploaded", isPresented: $vm.fileUploaded){
        Button("ok"){}
        Button("Link"){
          if let url = vm.fileDownloadURL{
            print("downloaded url: \(url)")
            UIApplication.shared.open(url)
          }
        }
      }
      
      if vm.isLoading {
        
          LoadingView()
      }
      
    }
  }
  
  func loadImage(){
    guard let inputImage = vm.inputImage else {
      return
    }
    vm.image = Image(uiImage: inputImage)
  }
  
  func uploadFromALocalFile(){
    let filePath = Auth.auth().currentUser!.uid +
    "/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\(imageURL.lastPathComponent)"
    // [START uploadimage]
    let storageRef = self.storage.reference(withPath: filePath)
    
    vm.isLoading = true
    storageRef.putFile(from: imageURL, metadata: nil) { metadata, error in
      guard let _ = metadata else {
        // Uh-oh, an error occurred!
        vm.errorFound = true
        vm.errInfo = error
        return
      }
      
      vm.isLoading = false
      // You can also access to download URL after upload.
      fetchDownloadURL(storageRef, storagePath: filePath)
    }
  }

  func uploadFromData(){
    guard let imageData = vm.inputImage?.jpeg else {
      print("The image from url \(imageURL.path) cannot be transferred to data.")
      return
    }
    let filePath = Auth.auth().currentUser!.uid +
    "/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/fromData/\(imageURL.lastPathComponent)"
    // [START uploadimage]
    let storageRef = self.storage.reference(withPath: filePath)
    
    vm.isLoading = true
    storageRef.putData(imageData, metadata: nil) { metadata, error in
      guard let _ = metadata else {
        // Uh-oh, an error occurred!
        vm.errorFound = true
        vm.errInfo = error
        return
      }
      vm.isLoading = false
      // You can also access to download URL after upload.
      fetchDownloadURL(storageRef, storagePath: filePath)
      
    }
    
  }
  
  func fetchDownloadURL(_ storageRef: StorageReference, storagePath: String) {
    storageRef.downloadURL { url, error in
      
      guard let downloadURL = url else {
        print("Error getting download URL: \(error.debugDescription)")
        vm.errorFound = true
        self.vm.errInfo = error
        return
      }
      print("download url: \(downloadURL.absoluteString)")
      UserDefaults.standard.set(storagePath, forKey: "storagePath")
      UserDefaults.standard.synchronize()
      vm.downloadPicButtonEnabled = true
      vm.fileUploaded = true
      vm.fileDownloadURL = downloadURL
      
    }
  }
  func download(){
    // Create a reference to the file you want to download
    let storageRef = Storage.storage().reference()
    
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    let documentsDirectory = paths[0]
    print (paths)
    let filePath = "file:\(documentsDirectory)/myimage.jpg"
    guard let fileURL = URL(string: filePath) else { return }
    guard let storagePath = UserDefaults.standard.object(forKey: "storagePath") as? String else {
      return
    }
    
    // [START downloadimage]
    
    vm.isLoading = true
    storageRef.child(storagePath).write(toFile: fileURL) { url, error in
      
      if let error = error {
        // Uh-oh, an error occurred!
        vm.errorFound = true
        vm.errInfo = error
      } else {
        vm.downloadDone = true
        vm.downloadedImage = Image(uiImage: UIImage(contentsOfFile: url!.path)!)
      }
      
      vm.isLoading = false
    }
  }
  
  func firebaseAuth(){
    
    // [START storageauth]
    // Using Cloud Storage for Firebase requires the user be authenticated. Here we are using
    // anonymous authentication.
    if Auth.auth().currentUser == nil {
      Auth.auth().signInAnonymously(completion: { authResult, error in
        if let error = error {
          vm.errorFound = true
          self.vm.errInfo = error
          self.authenticated = false
        } else {
          self.authenticated = true
        }
      })
    }
  }
}

struct OrangeButton: ButtonStyle {
  @Environment(\.isEnabled) private var isEnabled: Bool
  
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding()
      .background(isEnabled ? Color.orange : Color.orange.opacity(0.5))
      .foregroundColor(.white)
      .clipShape(RoundedRectangle(cornerRadius: 16.0))
  }
}

extension UIImage {
  var jpeg: Data? { jpegData(compressionQuality: 1) }
}

struct LoadingView: View{
  
  var body: some View{
    ZStack{
      Color(.systemBackground)
        .ignoresSafeArea()
        .opacity(0.5)
      ProgressView()
        .progressViewStyle(CircularProgressViewStyle(tint:.orange))
        .scaleEffect(3)
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
