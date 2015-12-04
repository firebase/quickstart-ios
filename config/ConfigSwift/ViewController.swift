//
//  Copyright (c) 2015 Google Inc.
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

//
// For more information on setting up and running this sample code, see
// https://developers.google.com/firebase/docs/remote-config/ios
//

import UIKit
import Firebase.Config

@objc(ViewController)
class ViewController: UIViewController {

  @IBOutlet weak var priceLabel: UILabel!
  @IBOutlet weak var debugLabel: UILabel!

  override func viewDidLoad() {

    super.viewDidLoad()

    // [START completion_handler]
    let completion:RCNDefaultConfigCompletion = {(config:RCNConfig!, status:RCNConfigStatus, error:NSError!) -> Void in
      if (error != nil) {
        // There has been an error fetching the config
        print("Error fetching config: \(error.localizedDescription)")
      } else {
        // Parse your config data
        // [START_EXCLUDE]
        // [START read_data]
        let isPromo = config.boolForKey("is_promo_on", defaultValue: false)
        let discount = config.numberForKey("discount", defaultValue: 0)
        // [END read_data]
        var price = 100.00
        if(isPromo) {
          price = (price / 100) * (price - discount.doubleValue);
        }
        let priceMsg = String(format:"Your price is $%.02f", price)
        self.priceLabel.text = priceMsg
        let isDevBuild = config.boolForKey("dev_features_on", defaultValue: false)
        if (isDevBuild) {
          let debugMsg = "Config set size: \(config.count)"
          self.debugLabel.text = debugMsg
        }
        // [END_EXCLUDE]
      }
    }
    // [END completion_handler]

    // [START fetch_config]
    let customVariables = ["build": "dev"]
    // 43200 secs = 12 hours
    RCNConfig.fetchDefaultConfigWithExpirationDuration(43200, customVariables: customVariables,
        completionHandler: completion)
    // [END fetch_config]
  }

}
