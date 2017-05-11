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
import FirebasePerformance

@objc(ViewController)
class ViewController: UIViewController {
    
  var trace: Trace!

  override func viewDidLoad() {
    super.viewDidLoad()

    // Start tracing
    self.trace = Performance.startTrace(name: "request_trace")
  }

  @IBAction func makeARequest(_ sender: AnyObject) {
    let target = "https://www.google.com"
    guard let targetUrl = URL(string: target) else { return }
    var request = URLRequest(url:targetUrl)
    request.httpMethod = "GET"

    let task = URLSession.shared.dataTask(with: request) {
      data, response, error in

      if let error = error {
        print("error=\(error)")
        return
      }

      let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
      print("Data received: \(responseString ?? "")")
    }

    task.resume()
    trace.incrementCounter(named: "request_sent")
  }

  deinit {
    trace.stop()
  }
}
