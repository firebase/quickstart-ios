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
import Vision

class Process: ObservableObject {
  @Published var status: ProcessStatus = .idle
  @Published var image: UIImage?
  @Published var saliencyMap: UIImage?
  var uploadSucceeded = false
  var categories: [(category: String, confidence: VNConfidence)]?
  lazy var context = CIContext()
  var isRunning: Bool {
    switch status {
    case .running:
      return true
    case .idle, .failure, .success:
      return false
    }
  }

  let precision: Float = 0.2
  let site = "https://firebase.google.com/downloads/brand-guidelines/PNG/logo-logomark.png"

  #if swift(>=5.5)
    @MainActor @available(iOS 15, tvOS 15,*)
    func updateStatusAsync(to newStatus: ProcessStatus, updateUploadStatus: Bool = false) {
      status = newStatus
      if updateUploadStatus { uploadSucceeded = newStatus == .success(.upload) }
    }

    @MainActor @available(iOS 15, tvOS 15, *) func updateImageAsync(to newImage: UIImage?) {
      image = newImage
    }

    @MainActor @available(iOS 15, tvOS 15, *)
    func updateSaliencyMapAsync(to newSaliencyMap: UIImage?) {
      saliencyMap = newSaliencyMap
    }

    @available(iOS 15, tvOS 15, *) func downloadImageAsync() async {
      await updateStatusAsync(to: .running(.download))

      guard let url = URL(string: site) else {
        await updateStatusAsync(to: .failure(.download))
        print("Failure obtaining URL.")
        return
      }

      do {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
          (200 ... 299).contains(httpResponse.statusCode) else {
          print("Did not receive acceptable response: \(response)")
          await updateStatusAsync(to: .failure(.download))
          return
        }

        guard let mimeType = httpResponse.mimeType, mimeType == "image/png",
          let image = UIImage(data: data) else {
          print("Could not create image from downloaded data.")
          await updateStatusAsync(to: .failure(.download))
          return
        }

        await updateStatusAsync(to: .success(.download))
        await updateImageAsync(to: image)

      } catch {
        print("Error downloading image: \(error).")
        await updateStatusAsync(to: .failure(.download))
      }
    }

    @available(iOS 15, tvOS 15, *) func classifyImageAsync() async {
      guard let uiImage = image, let ciImage = CIImage(image: uiImage) else {
        print("Could not convert image into correct format.")
        await updateStatusAsync(to: .failure(.classify))
        return
      }

      let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
      let request = VNClassifyImageRequest()
      await updateStatusAsync(to: .running(.classify))
      let trace = makeTrace(called: "Classification")
      trace?.start()
      try? handler.perform([request])
      trace?.stop()

      guard let observations = request.results else {
        print("Failed to obtain classification results.")
        await updateStatusAsync(to: .failure(.classify))
        return
      }

      categories = observations
        .filter { $0.hasMinimumRecall(0.01, forPrecision: precision) }
        .map { ($0.identifier, $0.confidence) }

      await updateStatusAsync(to: .success(.classify))
    }

    @available(iOS 15, tvOS 15, *) func generateSaliencyMapAsync() async {
      guard let uiImage = image, let ciImage = CIImage(image: uiImage) else {
        print("Could not convert image into correct format.")
        await updateStatusAsync(to: .failure(.saliencyMap))
        return
      }

      let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
      let request = VNGenerateAttentionBasedSaliencyImageRequest()
      await updateStatusAsync(to: .running(.saliencyMap))
      let trace = makeTrace(called: "Saliency_Map")
      trace?.start()
      try? handler.perform([request])
      trace?.stop()

      guard let observation = request.results?.first else {
        print("Failed to generate saliency map.")
        await updateStatusAsync(to: .failure(.saliencyMap))
        return
      }

      let inputImage = CIImage(cvPixelBuffer: observation.pixelBuffer)
      let scale = Double(ciImage.extent.height) / Double(inputImage.extent.height)
      let aspectRatio = Double(ciImage.extent.width) / Double(ciImage.extent.height)

      guard let scaleFilter = CIFilter(name: "CILanczosScaleTransform") else {
        print("Failed to create scaling filter.")
        await updateStatusAsync(to: .failure(.saliencyMap))
        return
      }

      scaleFilter.setValue(inputImage, forKey: kCIInputImageKey)
      scaleFilter.setValue(scale, forKey: kCIInputScaleKey)
      scaleFilter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)

      guard let scaledImage = scaleFilter.outputImage else {
        print("Failed to scale saliency map.")
        await updateStatusAsync(to: .failure(.saliencyMap))
        return
      }

      let saliencyImage = context.createCGImage(scaledImage, from: scaledImage.extent)

      guard let saliencyMap = saliencyImage else {
        print("Failed to convert saliency map to correct format.")
        await updateStatusAsync(to: .failure(.saliencyMap))
        return
      }

      await updateSaliencyMapAsync(to: UIImage(cgImage: saliencyMap))
      await updateStatusAsync(to: .success(.saliencyMap))
    }

    @available(iOS 15, tvOS 15, *)
    func uploadSaliencyMapAsync(compressionQuality: CGFloat = 0.5) async {
      guard let jpg = saliencyMap?.jpegData(compressionQuality: compressionQuality) else {
        print("Could not convert saliency map into correct format.")
        await updateStatusAsync(to: .failure(.upload), updateUploadStatus: true)
        return
      }

      let metadata = StorageMetadata()
      metadata.contentType = "image/jpeg"
      let reference = Storage.storage().reference().child("saliency_map.jpg")
      await updateStatusAsync(to: .running(.upload))

      do {
        let response = try await reference.putDataAsync(jpg, metadata: metadata)
        print("Upload response metadata: \(response)")
        await updateStatusAsync(to: .success(.upload), updateUploadStatus: true)
      } catch {
        print("Error uploading saliency map: \(error).")
        await updateStatusAsync(to: .failure(.upload), updateUploadStatus: true)
      }
    }
  #endif

  func updateStatus(to newStatus: ProcessStatus, updateUploadStatus: Bool = false) {
    DispatchQueue.main.async {
      self.status = newStatus
      if updateUploadStatus { self.uploadSucceeded = newStatus == .success(.upload) }
    }
  }

  func updateImage(to newImage: UIImage?) {
    DispatchQueue.main.async { self.image = newImage }
  }

  func updateSaliencyMap(to newSaliencyMap: UIImage?) {
    DispatchQueue.main.async { self.saliencyMap = newSaliencyMap }
  }

  func downloadImage() {
    updateStatus(to: .running(.download))
    guard let url = URL(string: site)
    else {
      updateStatus(to: .failure(.download))
      print("Failure obtaining URL.")
      return
    }
    let download = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
      guard error == nil else {
        print("Error encountered during download: \(String(describing: error))")
        self?.updateStatus(to: .failure(.download))
        return
      }
      guard let httpResponse = response as? HTTPURLResponse,
        (200 ... 299).contains(httpResponse.statusCode) else {
        print("Did not receive acceptable response: \(String(describing: response))")
        self?.updateStatus(to: .failure(.download))
        return
      }
      guard let mimeType = httpResponse.mimeType, mimeType == "image/png", let data = data,
        let image = UIImage(data: data) else {
        print("Something went wrong.")
        self?.updateStatus(to: .failure(.download))
        return
      }
      self?.updateStatus(to: .success(.download))
      self?.updateImage(to: image)
    }
    download.resume()
  }

  func classifyImage() {
    guard let uiImage = image, let ciImage = CIImage(image: uiImage) else {
      print("Could not convert image into correct format.")
      updateStatus(to: .failure(.classify))
      return
    }

    let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
    let request = VNClassifyImageRequest()
    updateStatus(to: .running(.classify))
    let trace = makeTrace(called: "Classification")
    trace?.start()
    try? handler.perform([request])
    trace?.stop()

    #if swift(>=5.5)
      guard let observations = request.results else {
        print("Failed to obtain classification results.")
        updateStatus(to: .failure(.classify))
        return
      }
    #else
      guard let observations = request.results as? [VNClassificationObservation] else {
        print("Failed to obtain classification results.")
        updateStatus(to: .failure(.classify))
        return
      }
    #endif

    categories = observations
      .filter { $0.hasMinimumRecall(0.01, forPrecision: precision) }
      .map { ($0.identifier, $0.confidence) }

    updateStatus(to: .success(.classify))
  }

  func generateSaliencyMap() {
    guard let uiImage = image, let ciImage = CIImage(image: uiImage) else {
      print("Could not convert image into correct format.")
      updateStatus(to: .failure(.saliencyMap))
      return
    }

    let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
    let request = VNGenerateAttentionBasedSaliencyImageRequest()
    updateStatus(to: .running(.saliencyMap))
    let trace = makeTrace(called: "Saliency_Map")
    trace?.start()
    try? handler.perform([request])
    trace?.stop()

    #if swift(>=5.5)
      guard let observation = request.results?.first else {
        print("Failed to generate saliency map.")
        updateStatus(to: .failure(.saliencyMap))
        return
      }
    #else
      guard let observation = request.results?.first as? VNSaliencyImageObservation else {
        print("Failed to generate saliency map.")
        updateStatus(to: .failure(.saliencyMap))
        return
      }
    #endif

    let inputImage = CIImage(cvPixelBuffer: observation.pixelBuffer)
    let scale = Double(ciImage.extent.height) / Double(inputImage.extent.height)
    let aspectRatio = Double(ciImage.extent.width) / Double(ciImage.extent.height)

    guard let scaleFilter = CIFilter(name: "CILanczosScaleTransform") else {
      print("Failed to create scaling filter.")
      updateStatus(to: .failure(.saliencyMap))
      return
    }

    scaleFilter.setValue(inputImage, forKey: kCIInputImageKey)
    scaleFilter.setValue(scale, forKey: kCIInputScaleKey)
    scaleFilter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)

    guard let scaledImage = scaleFilter.outputImage else {
      print("Failed to scale saliency map.")
      updateStatus(to: .failure(.saliencyMap))
      return
    }

    let saliencyImage = context.createCGImage(scaledImage, from: scaledImage.extent)

    guard let saliencyMap = saliencyImage else {
      print("Failed to convert saliency map to correct format.")
      updateStatus(to: .failure(.saliencyMap))
      return
    }

    updateSaliencyMap(to: UIImage(cgImage: saliencyMap))
    updateStatus(to: .success(.saliencyMap))
  }

  func uploadSaliencyMap(compressionQuality: CGFloat = 0.5) {
    guard let jpg = saliencyMap?.jpegData(compressionQuality: compressionQuality) else {
      print("Could not convert saliency map into correct format.")
      updateStatus(to: .failure(.upload), updateUploadStatus: true)
      return
    }

    let metadata = StorageMetadata()
    metadata.contentType = "image/jpeg"
    let reference = Storage.storage().reference().child("saliency_map.jpg")
    updateStatus(to: .running(.upload))

    reference.putData(jpg, metadata: metadata) { [weak self] result in
      switch result {
      case let .success(response):
        print("Upload response metadata: \(response)")
        self?.updateStatus(to: .success(.upload), updateUploadStatus: true)
      case let .failure(error):
        print("Error uploading saliency map: \(error).")
        self?.updateStatus(to: .failure(.upload), updateUploadStatus: true)
      }
    }
  }

  func makeTrace(called name: String) -> Trace? {
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
