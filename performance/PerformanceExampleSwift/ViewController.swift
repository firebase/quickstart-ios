//
//  Copyright (c) 2016 Google Inc.
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

import UIKit
import Firebase
import AVKit
import AVFoundation

@objc(ViewController)
class ViewController: UIViewController {
  @IBOutlet var imageView: UIImageView!

  override func viewDidLoad() {
    super.viewDidLoad()

    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    let documentsDirectory = paths[0]

    // make a file name to write the data to using the documents directory
    let fileName = "\(documentsDirectory)/perfsamplelog.txt"

    // Start tracing
    let trace = Performance.startTrace(name: "request_trace")

    let contents: String
    do {
      contents = try String(contentsOfFile: fileName, encoding: .utf8)
    } catch {
      print("Log file doesn't exist yet")
      contents = ""
    }

    let fileLength = contents.lengthOfBytes(using: .utf8)

    trace?.incrementMetric("log_file_size", by: Int64(fileLength))

    let target =
      "https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png"
    guard let targetUrl = URL(string: target) else { return }
    guard let metric = HTTPMetric(url: targetUrl, httpMethod: .get) else { return }
    metric.start()

    var request = URLRequest(url: targetUrl)
    request.httpMethod = "GET"

    let task = URLSession.shared.dataTask(with: request) {
      data, response, error in

      if let httpResponse = response as? HTTPURLResponse {
        metric.responseCode = httpResponse.statusCode
      }
      metric.stop()

      if let error = error {
        print("error=\(error)")
        return
      }

      DispatchQueue.main.async {
        self.imageView.image = UIImage(data: data!)
      }

      trace?.stop()

      if let absoluteString = response?.url?.absoluteString {
        let contentToWrite = contents + "\n" + absoluteString
        do {
          try contentToWrite.write(toFile: fileName, atomically: false, encoding: .utf8)
        } catch {
          print("Can't write to log file")
        }
      }
    }

    task.resume()
    trace?.incrementMetric("request_sent", by: 1)

    if #available(iOS 10, *) {
      let asset =
        AVURLAsset(
          url: URL(
            string: "https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Two_red_dice_01.svg/220px-Two_red_dice_01.svg.png"
          )!
        )
      let downloadSession =
        AVAssetDownloadURLSession(
          configuration: URLSessionConfiguration.background(withIdentifier: "avasset"),
          assetDownloadDelegate: nil,
          delegateQueue: OperationQueue.main
        )

      let task = downloadSession.makeAssetDownloadTask(asset: asset,
                                                       assetTitle: "something",
                                                       assetArtworkData: nil,
                                                       options: nil)!
      task.resume()
      trace?.incrementMetric("av_request_sent", by: 1)
    }
  }
}
