//
//  Copyright (c) 2018 Google Inc.
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
import FirebaseMLVision
import MobileCoreServices

protocol DetectorDelegate {
  func imageSelected(image: UIImage)
}

class DetectionViewController : UIViewController, UIImagePickerControllerDelegate,  UIPopoverPresentationControllerDelegate, UINavigationControllerDelegate {
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var textView: UITextView!
  var faceSublayer = CALayer()
  var detectorDelegate: DetectorDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    imageView.layer.addSublayer(faceSublayer)
  }
  
  @IBAction func touchLibrary(_ sender: UIButton) {
    clearFrames()
    presentImagePickerController(with: .photoLibrary)
  }
  
  
  @IBAction func touchCamera(_ sender: UIButton) {
    clearFrames()
    presentImagePickerController(with: .camera)
  }
  
  
  func presentImagePickerController(with sourceType: UIImagePickerControllerSourceType) {
    let controller = UIImagePickerController()
    controller.delegate = self
    controller.sourceType = sourceType
    controller.mediaTypes = [String(kUTTypeImage)]
    if sourceType == .photoLibrary {
      controller.modalPresentationStyle = .popover
      let presenter = controller.popoverPresentationController
      presenter?.sourceView = view
      presenter?.delegate = self
    }
    present(controller, animated: true)
  }
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage{
      dismiss(animated: true) {
        self.detectorDelegate?.imageSelected(image: pickedImage)
      }
    }
  }
  
  func addFrameView(featureFrame: CGRect, imageSize: CGSize, viewFrame: CGRect) {
    print("Found a face: \(featureFrame).\n")
    
    let viewSize = viewFrame.size
    
    // Find resolution for the view and image
    let rView = viewSize.width / viewSize.height
    let rImage = imageSize.width / imageSize.height
    
    // Define scale based on comparing resolutions
    var scale: CGFloat
    if rView > rImage {
      scale = viewSize.height / imageSize.height
    } else {
      scale = viewSize.width / imageSize.width
    }
    
    // Calculate scaled feature frame size
    let featureWidthScaled = featureFrame.size.width * scale
    let featureHeightScaled = featureFrame.size.height * scale
    
    // Calculate scaled feature frame top-left point
    let imageWidthScaled = imageSize.width * scale
    let imageHeightScaled = imageSize.height * scale
    
    let imagePointXScaled = (viewSize.width - imageWidthScaled)  / 2
    let imagePointYScaled = (viewSize.height - imageHeightScaled)  / 2
    
    let featurePointXScaled = imagePointXScaled + featureFrame.origin.x * scale
    let featurePointYScaled = imagePointYScaled + featureFrame.origin.y * scale
    
    // Define a rect for scaled feature frame
    let featureRectScaled = CGRect(x: featurePointXScaled,
                                   y: featurePointYScaled,
                                   width: featureWidthScaled,
                                   height: featureHeightScaled)
    
    drawFrame(featureRectScaled)
  }
  
  func drawFrame(_ rect: CGRect) {
    let bpath: UIBezierPath = UIBezierPath(rect: rect)
    
    let rectLayer: CAShapeLayer = CAShapeLayer()
    rectLayer.path = bpath.cgPath
    rectLayer.strokeColor = UIColor.red.cgColor
    rectLayer.fillColor = UIColor.clear.cgColor
    rectLayer.lineWidth = 1
    
    faceSublayer.addSublayer(rectLayer)
  }
  
  func clearFrames() {
    if faceSublayer.sublayers != nil {
      for sublayer in faceSublayer.sublayers! {
        guard let faceLayer = sublayer as CALayer? else {
          fatalError("Error in layers")
        }
        faceLayer.removeFromSuperlayer()
      }
    }
  }
  
}
