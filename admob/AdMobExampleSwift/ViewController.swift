//
// Copyright (c) 2015 Google Inc.
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
//  ViewController.swift
//  AdMobExampleSwift
//

// [START firebase_banner_example]
import UIKit
import Firebase

/**
 * AdMob ad unit IDs are not currently stored inside the google-services.plist file. Developers
 * using AdMob can store them as custom values in another plist, or simply use constants. Note that
 * these ad units are configured to return only test ads, and should not be used outside this sample.
 */
let kBannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
let kInterstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"

// Makes ViewController available to Objc classes.
@objc(ViewController)
class ViewController: UIViewController, GADInterstitialDelegate {
  @IBOutlet weak var bannerView: GADBannerView!
  var interstitial: GADInterstitial!
  @IBOutlet weak var interstitialButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()

    self.bannerView.adUnitID = kBannerAdUnitID
    self.bannerView.rootViewController = self
    self.bannerView.load(GADRequest())
    // [END firebase_banner_example]

    // [START firebase_interstitial_example]
    self.interstitial = createAndLoadInterstitial()
    self.interstitialButton.isEnabled = self.interstitial.isReady
  }

  func createAndLoadInterstitial() -> GADInterstitial {
    let interstitial =
        GADInterstitial(adUnitID: kInterstitialAdUnitID)
    interstitial.delegate = self
    interstitial.load(GADRequest())
    return interstitial
  }

  func interstitialDidReceiveAd(_ ad: GADInterstitial) {
    self.interstitialButton.isEnabled = true
  }

  func interstitialDidDismissScreen(_ interstitial: GADInterstitial) {
    self.interstitialButton.isEnabled = false
    self.interstitial = createAndLoadInterstitial()
  }

  @IBAction func didTapInterstitialButton(_ sender: AnyObject) {
    if self.interstitial.isReady {
      self.interstitial.present(fromRootViewController: self)
    }
  }

  func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
    // Retrying failed interstitial loads is a rudimentary way of handling these errors.
    // For more fine-grained error handling, take a look at the values in GADErrorCode.
    self.interstitial = createAndLoadInterstitial()
  }
}
// [END firebase_interstitial_example]
