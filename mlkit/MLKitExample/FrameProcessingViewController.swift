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
import AVFoundation
import FirebaseMLVision

let SEGUE_IDENTIFIER = "FRAME_TO_PHOTO"
typealias TextPhoto = (String, UIImage)

class FrameProcessingViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
  let captureSession = AVCaptureSession()
  var previewLayer: CALayer!
  
  var captureDevice: AVCaptureDevice!
  var shouldTakePhoto = false
  
  var textDetector: VisionTextDetector!
  var frameCount = 0
  
  @IBOutlet weak var cameraView: UIView!
  @IBOutlet weak var textView: UITextView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.addRightButtonBarItem()
    
    textDetector = Vision().textDetector()
    prepareCamera()
  }
  
  func addRightButtonBarItem() {
    let rightButton = UIBarButtonItem(title: "Take", style: .plain, target: self, action: #selector(FrameProcessingViewController.cameraDidTouch))
    self.navigationItem.rightBarButtonItem = rightButton
  }
  
  // MARK: Navigation methods
  
  @objc func cameraDidTouch() {
    // Flip the photo bit to true so it triggers the photo action
    // in the captureOutput loop below
    shouldTakePhoto = true
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == SEGUE_IDENTIFIER {
      let vc = segue.destination as! PhotoCaptureViewController
      let tuple = sender as! TextPhoto
      vc.detectedText = tuple.0
      vc.capturedImage = tuple.1
    }
  }
  
  // MARK: Camera methods
  
  // Create an AVCaptureSession and begin streaming
  func prepareCamera() {
    captureSession.sessionPreset = AVCaptureSession.Preset.medium
    captureDevice = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInWideAngleCamera],
      mediaType: AVMediaType.video, position:
      AVCaptureDevice.Position.back
    ).devices.first
    beginSession()
  }
  
  // Begin an AVCaptureSession by findinding a device and creating a layer
  // to stream the frames to
  func beginSession() {
    do {
      let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
      captureSession.addInput(captureDeviceInput)
    } catch {
      print(error.localizedDescription)
    }
    
    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    view.layer.addSublayer(previewLayer)
    
    // Match preview layer to camera view's size and position
    previewLayer.frame = cameraView.frame
    previewLayer.bounds = cameraView.bounds
    
    captureSession.startRunning()
    
    let dataOutput = AVCaptureVideoDataOutput()
    dataOutput.videoSettings = [
      ((kCVPixelBufferPixelFormatTypeKey as NSString) as String): NSNumber(value: kCVPixelFormatType_32BGRA)
    ]
    
    dataOutput.alwaysDiscardsLateVideoFrames = true
    
    if captureSession.canAddOutput(dataOutput) {
      captureSession.addOutput(dataOutput)
    }
    
    captureSession.commitConfiguration()
    
    let queue = DispatchQueue(label: "captureQueue")
    dataOutput.setSampleBufferDelegate(self, queue: queue)
  }
  
  // Process frames only at a specific duration. This skips redundant frames and
  // avoids memory issues.
  func proccess(every: Int, callback: () -> Void) {
    frameCount = frameCount + 1
    // Process every nth frame
    if(frameCount % every == 0) {
      callback()
    }
  }
  
  // Combine all VisionText into one String
  private func flattenVisionText(visionText: [VisionText]?) -> String {
    var text = ""
    visionText?.forEach(){ vText in
      text += " " + vText.text
    }
    return text
  }
  
  // Detect text in a CMSampleBuffer by converting to a UIImage to determine orientation
  func detectText(in buffer: CMSampleBuffer, completion: @escaping (_ text: String, _ image: UIImage) -> Void) {
    if let image = buffer.toUIImage() {
      let viImage = image.toVisionImage()
      textDetector.detect(in: viImage) { (visionText, error) in
        completion(self.flattenVisionText(visionText: visionText), image)
      }
    }
  }
  
  // Take a photo and segue to PhotoCaptureViewControlelr
  func takePhoto(buffer: CMSampleBuffer) {
    shouldTakePhoto = false
    self.detectText(in: buffer) { text, image  in
      let tuple: TextPhoto = (text, image)
      self.performSegue(withIdentifier: SEGUE_IDENTIFIER, sender: tuple)
    }
  }
  
  // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
  
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    
    // Detect text every 10 frames
    proccess(every: 10) {
      self.detectText(in: sampleBuffer) { text, image in
        self.textView.text = text
      }
    }
    
    if shouldTakePhoto {
      takePhoto(buffer: sampleBuffer)
    }
    
  }
  
}
