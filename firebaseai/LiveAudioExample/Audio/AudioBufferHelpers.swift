// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import AVFoundation

extension AVAudioPCMBuffer {
  /// Creates a new `AVAudioPCMBuffer` from a `Data` struct.
  ///
  /// Only works with interleaved data.
  static func fromInterleavedData(data: Data, format: AVAudioFormat) -> AVAudioPCMBuffer? {
    guard format.isInterleaved else {
      fatalError("Only interleaved data is supported")
    }

    let frameCapacity = AVAudioFrameCount(data
      .count / Int(format.streamDescription.pointee.mBytesPerFrame))
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else {
      return nil
    }

    buffer.frameLength = frameCapacity
    data.withUnsafeBytes { bytes in
      guard let baseAddress = bytes.baseAddress else { return }
      let dst = buffer.mutableAudioBufferList.pointee.mBuffers
      dst.mData?.copyMemory(from: baseAddress, byteCount: Int(dst.mDataByteSize))
    }

    return buffer
  }

  /// Gets the underlying `Data` in this buffer.
  ///
  /// Will throw an error if this buffer doesn't hold int16 data.
  func int16Data() -> Data? {
    guard let bufferPtr = audioBufferList.pointee.mBuffers.mData else {
      fatalError("Missing audio buffer list")
    }

    let audioBufferLenth = Int(audioBufferList.pointee.mBuffers.mDataByteSize)
    return Data(bytes: bufferPtr, count: audioBufferLenth)
  }
}

extension AVAudioConverter {
  /// Uses the converter to convert the provided `buffer`.
  ///
  /// Will handle determining the proper frame capacity, ensuring formats align, and propogating any errors that occur.
  ///
  ///   - Returns: A new buffer, with the converted data.
  func convertBuffer(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer {
    if buffer.format == outputFormat { return buffer }
    guard buffer.format == inputFormat else {
      fatalError("The buffer's format was different than the converter's input format")
    }

    let frameCapacity = AVAudioFrameCount(
      ceil(Double(buffer.frameLength) * outputFormat.sampleRate / inputFormat.sampleRate)
    )

    guard let output = AVAudioPCMBuffer(
      pcmFormat: outputFormat,
      frameCapacity: frameCapacity
    ) else {
      fatalError("Failed to create output buffer")
    }

    var error: NSError?
    convert(to: output, error: &error) { _, status in
      status.pointee = .haveData
      return buffer
    }

    if let error {
      fatalError("Failed to convert buffer: \(error.localizedDescription)")
    }

    return output
  }
}
