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
import GoogleMobileAds

/**
 * AdMob ad unit IDs are not currently stored inside the google-services.plist file. Developers
 * using AdMob can store them as custom values in another plist, or simply use constants. Note that
 * these ad units are configured to return only test ads, and should not be used outside this sample.
 */
let kBannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
let kInterstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"

// Makes ViewController available to Objc classes.
@objc(ViewController)
class ViewController: UIViewController, GADFullScreenContentDelegate {
  @IBOutlet var bannerView: GADBannerView!
  var interstitial: GADInterstitialAd?
  @IBOutlet var interstitialButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()

    bannerView.adUnitID = kBannerAdUnitID
    bannerView.rootViewController = self
    bannerView.load(GADRequest())
    // [END firebase_banner_example]

    // [START firebase_interstitial_example]
    createAndLoadInterstitial()
  }

  func createAndLoadInterstitial() {
    GADInterstitialAd.load(
      withAdUnitID: kInterstitialAdUnitID,
      request: GADRequest()
    ) { ad, error in
      if let error = error {
        // For more fine-grained error handling, take a look at the values in GADErrorCode.
        print("Error loading ad: \(error)")
      }
      self.interstitial = ad
      self.interstitialButton.isEnabled = true
    }
  }

  func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
    interstitialButton.isEnabled = false
    createAndLoadInterstitial()
  }

  func ad(_ ad: GADFullScreenPresentingAd,
          didFailToPresentFullScreenContentWithError error: Error) {
    print("Error presenting ad: \(error)")
  }

  @IBAction func didTapInterstitialButton(_ sender: AnyObject) {
    interstitial?.present(fromRootViewController: self)
  }
}

// [END firebase_interstitial_example]
