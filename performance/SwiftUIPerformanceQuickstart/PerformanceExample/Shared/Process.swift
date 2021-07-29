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

class Process: ObservableObject {
  @Published var status: ProcessStatus = .idle
  @Published var action: ProcessAction?
  @Published var image: Image?

  #if swift(>=5.5)
    @MainActor @available(
      iOS 15,
      tvOS 15,
      *
    ) func updateStatusAsync(to newStatus: ProcessStatus) { status = newStatus }

    @MainActor @available(iOS 15, tvOS 15, *) func updateImageAsync(to newImage: Image?) {
      image = newImage
    }

    @available(iOS 15, tvOS 15, *) func downloadImageAsync() async {
      await updateStatusAsync(to: .running)

      guard let url =
        URL(string: "https://www.gstatic.com/devrel-devsite/prod/v854c54f3442b5b06d9" +
          "7cb2bf43f3647f489796c80c33899ecd29b91ae5303388/firebase/images/lockup.png")
      else {
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
        await updateImageAsync(to: Image(uiImage: image))

      } catch {
        print("Error downloading image: \(error).")
        await updateStatusAsync(to: .failure)
      }
    }

    @available(iOS 15, tvOS 15, *) func modifyImageAsync() async {
      switch status {
      case .idle, .running:
        return
      case .failure, .success:
        await updateStatusAsync(to: .idle)
        await updateImageAsync(to: nil)
      }
    }

    @available(iOS 15, tvOS 15, *) func uploadImageAsync() async {}
  #endif

  func updateStatus(to newStatus: ProcessStatus) {
    DispatchQueue.main.async { self.status = newStatus }
  }

  func updateImage(to newImage: Image?) {
    DispatchQueue.main.async { self.image = newImage }
  }

  func downloadImage() {
    updateStatus(to: .running)
    guard let url =
      URL(string: "https://www.gstatic.com/devrel-devsite/prod/v854c54f3442b5b06d9" +
        "7cb2bf43f3647f489796c80c33899ecd29b91ae5303388/firebase/images/lockup.png")
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
      self?.updateImage(to: Image(uiImage: image))
    }
    download.resume()
  }

  func modifyImage() {
    switch status {
    case .idle, .running:
      return
    case .failure, .success:
      updateStatus(to: .idle)
      updateImage(to: nil)
    }
  }

  func uploadImage() {}
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

enum ProcessAction: String, CaseIterable {
  case download = "Download"
  case modify = "Modify"
  case upload = "Upload"
}
