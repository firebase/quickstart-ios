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

import Foundation
import AVFoundation
import UIKit
import CoreImage
import Firebase

extension CMSampleBuffer {
  
  // Converts a CMSampleBuffer to a UIImage
  //
  // Return: UIImage from CMSampleBuffer
  func toUIImage() -> UIImage? {
    if let pixelBuffer = CMSampleBufferGetImageBuffer(self) {
      let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
      let context = CIContext()
      let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
      
      if let image = context.createCGImage(ciImage, from: imageRect) {
        return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .right)
      }
      
    }
    return nil
  }
  
}
