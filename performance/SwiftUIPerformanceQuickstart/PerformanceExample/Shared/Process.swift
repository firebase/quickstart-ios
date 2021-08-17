//
//  Copyright 2021 Google LLC
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
import FirebasePerformance
import FirebaseStorage
import FirebaseStorageSwift
import Vision

class Process: ObservableObject {
  @Published var status: ProcessStatus = .idle
  @Published var image: UIImage?
  var uploadSucceeded = false
  var categories: [(category: String, confidence: VNConfidence)]?
  let precision: Float = 0.2
  let site = "https://firebase.google.com/downloads/brand-guidelines/PNG/logo-logomark.png"

  #if swift(>=5.5)
    @MainActor @available(iOS 15, tvOS 15,*)
    func updateStatusAsync(to newStatus: ProcessStatus, updateUploadStatus: Bool = false) {
      status = newStatus
      if updateUploadStatus { uploadSucceeded = newStatus == .success }
    }

    @MainActor @available(iOS 15, tvOS 15, *) func updateImageAsync(to newImage: UIImage?) {
      image = newImage
    }

    @available(iOS 15, tvOS 15, *) func downloadImageAsync() async {
      await updateStatusAsync(to: .running)

      guard let url = URL(string: site) else {
        await updateStatusAsync(to: .failure)
        print("Failure obtaining URL.")
        return
      }

      do {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
          (200 ... 299).contains(httpResponse.statusCode) else {
          print("Did not receive acceptable response: \(response)")
          await updateStatusAsync(to: .failure)
          return
        }

        guard let mimeType = httpResponse.mimeType, mimeType == "image/png",
          let image = UIImage(data: data) else {
          print("Could not create image from downloaded data.")
          await updateStatusAsync(to: .failure)
          return
        }

        await updateStatusAsync(to: .success)
        await updateImageAsync(to: image)

      } catch {
        print("Error downloading image: \(error).")
        await updateStatusAsync(to: .failure)
      }
    }

    @available(iOS 15, tvOS 15, *) func classifyImageAsync() async {
      guard let uiImage = image, let ciImage = CIImage(image: uiImage) else {
        print("Could not convert image into correct format.")
        await updateStatusAsync(to: .failure)
        return
      }

      let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
      let request = VNClassifyImageRequest()
      await updateStatusAsync(to: .running)
      let trace = makeTrace()
      trace?.start()
      try? handler.perform([request])
      trace?.stop()

      guard let observations = request.results as? [VNClassificationObservation] else {
        print("Failed to obtain classification results.")
        await updateStatusAsync(to: .failure)
        return
      }

      categories = observations
        .filter { $0.hasMinimumRecall(0.01, forPrecision: precision) }
        .map { ($0.identifier, $0.confidence) }

      await updateStatusAsync(to: .success)
    }

    @available(iOS 15, tvOS 15, *) func uploadImageAsync(compressionQuality: CGFloat = 0.5) async {
      guard let jpg = image?.jpegData(compressionQuality: compressionQuality) else {
        print("Could not convert image into correct format.")
        await updateStatusAsync(to: .failure, updateUploadStatus: true)
        return
      }

      let metadata = StorageMetadata()
      metadata.contentType = "image/jpeg"
      let reference = Storage.storage().reference().child("image.jpg")
      await updateStatusAsync(to: .running)

      do {
        let response = try await reference.putDataAsync(jpg, metadata: metadata)
        print("Upload response metadata: \(response)")
        await updateStatusAsync(to: .success, updateUploadStatus: true)
      } catch {
        print("Error uploading image: \(error).")
        await updateStatusAsync(to: .failure, updateUploadStatus: true)
      }
    }
  #endif

  func updateStatus(to newStatus: ProcessStatus, updateUploadStatus: Bool = false) {
    DispatchQueue.main.async {
      self.status = newStatus
      if updateUploadStatus { self.uploadSucceeded = newStatus == .success }
    }
  }

  func updateImage(to newImage: UIImage?) {
    DispatchQueue.main.async { self.image = newImage }
  }

  func downloadImage() {
    updateStatus(to: .running)
    guard let url = URL(string: site)
    else {
      updateStatus(to: .failure)
      print("Failure obtaining URL.")
      return
    }
    let download = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
      guard error == nil else {
        print("Error encountered during download: \(String(describing: error))")
        self?.updateStatus(to: .failure)
        return
      }
      guard let httpResponse = response as? HTTPURLResponse,
        (200 ... 299).contains(httpResponse.statusCode) else {
        print("Did not receive acceptable response: \(String(describing: response))")
        self?.updateStatus(to: .failure)
        return
      }
      guard let mimeType = httpResponse.mimeType, mimeType == "image/png", let data = data,
        let image = UIImage(data: data) else {
        print("Something went wrong.")
        self?.updateStatus(to: .failure)
        return
      }
      self?.updateStatus(to: .success)
      self?.updateImage(to: image)
    }
    download.resume()
  }

  func classifyImage() {
    guard let uiImage = image, let ciImage = CIImage(image: uiImage) else {
      print("Could not convert image into correct format.")
      updateStatus(to: .failure)
      return
    }

    let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
    let request = VNClassifyImageRequest()
    updateStatus(to: .running)
    let trace = makeTrace()
    trace?.start()
    try? handler.perform([request])
    trace?.stop()

    guard let observations = request.results as? [VNClassificationObservation] else {
      print("Failed to obtain classification results.")
      updateStatus(to: .failure)
      return
    }

    categories = observations
      .filter { $0.hasMinimumRecall(0.01, forPrecision: precision) }
      .map { ($0.identifier, $0.confidence) }

    updateStatus(to: .success)
  }

  func uploadImage(compressionQuality: CGFloat = 0.5) {
    guard let jpg = image?.jpegData(compressionQuality: compressionQuality) else {
      print("Could not convert image into correct format.")
      updateStatus(to: .failure, updateUploadStatus: true)
      return
    }

    let metadata = StorageMetadata()
    metadata.contentType = "image/jpeg"
    let reference = Storage.storage().reference().child("image.jpg")
    updateStatus(to: .running)

    reference.putData(jpg, metadata: metadata) { [weak self] result in
      switch result {
      case let .success(response):
        print("Upload response metadata: \(response)")
        self?.updateStatus(to: .success, updateUploadStatus: true)
      case let .failure(error):
        print("Error uploading image: \(error).")
        self?.updateStatus(to: .failure, updateUploadStatus: true)
      }
    }
  }

  func makeTrace(called name: String = "Classification") -> Trace? {
    #if os(tvOS)
      let platform = "tvOS"
    #elseif os(iOS)
      let platform = "iOS"
    #else
      fatalError("Unsupported platform.")
    #endif
    let trace = Performance.sharedInstance().trace(name: name)
    trace?.setValue("\(precision)", forAttribute: "precision")
    trace?.setValue(platform, forAttribute: "platform")
    return trace
  }
}

enum ProcessStatus {
  case idle, running, failure, success

  var view: some View {
    HStack {
      switch self {
      case .idle:
        Text("⏸ Idle")
      case .running:
        ProgressView().padding(.trailing, 1.0)
        Text("Running")
      case .failure:
        Text("❌ Failure")
      case .success:
        Text("✅ Success")
      }
    }
  }
}
