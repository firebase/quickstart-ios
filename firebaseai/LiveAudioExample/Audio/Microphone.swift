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

import Foundation
import AVFoundation

/// Microphone bindings using Apple's AudioEngine API.
class Microphone {
  /// Data recorded from the microphone.
  public let audio: AsyncStream<AVAudioPCMBuffer>
  private let audioQueue: AsyncStream<AVAudioPCMBuffer>.Continuation

  private let inputNode: AVAudioInputNode
  private let audioEngine: AVAudioEngine

  private var isRunning = false

  init(engine: AVAudioEngine) {
    let (audio, audioQueue) = AsyncStream<AVAudioPCMBuffer>.makeStream()

    self.audio = audio
    self.audioQueue = audioQueue
    self.inputNode = engine.inputNode
    self.audioEngine = engine
  }

  deinit {
    stop()
  }

  public func start() {
    guard !isRunning else { return }
    isRunning = true

    // 50ms buffer size for balancing latency and cpu overhead
    let targetBufferSize = UInt32(inputNode.outputFormat(forBus: 0).sampleRate / 20)
    inputNode.installTap(onBus: 0, bufferSize: targetBufferSize, format: nil) { [weak self] buffer, _ in
      guard let self else { return }
      audioQueue.yield(buffer)
    }
  }

  public func stop() {
    audioQueue.finish()
    if isRunning {
      isRunning = false
      inputNode.removeTap(onBus: 0)
    }
  }
}
