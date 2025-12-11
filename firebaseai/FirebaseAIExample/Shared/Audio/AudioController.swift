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
import OSLog

#if compiler(<6.2)
extension AVAudioSession.CategoryOptions {
  static let allowBluetoothHFP = AVAudioSession.CategoryOptions.allowBluetooth
}
#endif

/// Controls audio playback and recording.
actor AudioController {
  private var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "generative-ai")

  /// Data processed from the microphone.
  private let microphoneData: AsyncStream<AVAudioPCMBuffer>
  private let microphoneDataQueue: AsyncStream<AVAudioPCMBuffer>.Continuation
  private var audioPlayer: AudioPlayer?
  private var audioEngine: AVAudioEngine?
  private var microphone: Microphone?
  private var listenTask: Task<Void, Error>?
  private var routeTask: Task<Void, Never>?

  /// Port types that are considered "headphones" for our use-case.
  ///
  /// More specifically, airpods are considered bluetooth ports instead of headphones, so
  /// this array is necessary.
  private let headphonePortTypes: [AVAudioSession.Port] = [
    .headphones,
    .bluetoothA2DP,
    .bluetoothLE,
    .bluetoothHFP,
  ]

  private let modelInputFormat: AVAudioFormat
  private let modelOutputFormat: AVAudioFormat

  private var stopped = false

  public init() async throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(
      .playAndRecord,
      mode: .voiceChat,
      options: [.defaultToSpeaker, .allowBluetoothHFP, .duckOthers,
                .interruptSpokenAudioAndMixWithOthers, .allowBluetoothA2DP]
    )
    try session.setPreferredIOBufferDuration(0.01)
    try session.setActive(true)

    guard let modelInputFormat = AVAudioFormat(
      commonFormat: .pcmFormatInt16,
      sampleRate: 16000,
      channels: 1,
      interleaved: false
    ) else {
      throw ApplicationError("Failed to create model input format")
    }

    guard let modelOutputFormat = AVAudioFormat(
      commonFormat: .pcmFormatInt16,
      sampleRate: 24000,
      channels: 1,
      interleaved: true
    ) else {
      throw ApplicationError("Failed to create model output format")
    }

    self.modelInputFormat = modelInputFormat
    self.modelOutputFormat = modelOutputFormat

    let (processedData, dataQueue) = AsyncStream<AVAudioPCMBuffer>.makeStream()
    microphoneData = processedData
    microphoneDataQueue = dataQueue

    listenForRouteChange()
  }

  /// Kicks off audio processing, and returns a stream of recorded microphone audio data.
  public func listenToMic() async throws -> AsyncStream<AVAudioPCMBuffer> {
    try await spawnAudioProcessingThread()
    return microphoneData
  }

  /// Permanently stop all audio processing.
  ///
  /// To start again, create a new instance of ``AudioController``.
  public func stop() async {
    stopped = true
    await stopListeningAndPlayback()
    microphoneDataQueue.finish()
    routeTask?.cancel()
  }

  /// Queues audio for playback.
  public func playAudio(audio: Data) async throws {
    try audioPlayer?.play(audio)
  }

  /// Interrupts and clears the currently pending audio playback queue.
  public func interrupt() async {
    audioPlayer?.interrupt()
  }

  private func stopListeningAndPlayback() async {
    listenTask?.cancel()
    // audio engine needs to be stopped before disconnecting nodes
    audioEngine?.pause()
    audioEngine?.stop()
    if let audioEngine {
      do {
        // the VP IO leaves behind artifacts, so we need to disable it to properly clean up
        if audioEngine.inputNode.isVoiceProcessingEnabled {
          try audioEngine.inputNode.setVoiceProcessingEnabled(false)
        }
      } catch {
        logger.error("Failed to disable voice processing: \(error.localizedDescription)")
      }
    }
    microphone?.stop()
    audioPlayer?.stop()
  }

  /// Start audio processing functionality.
  ///
  /// Will stop any currently running audio processing.
  ///
  /// This function is also called whenever the input or output device change,
  /// so it needs to be able to setup the audio processing without disrupting
  /// the consumer of the microphone data.
  private func spawnAudioProcessingThread() async throws {
    if stopped { return }

    await stopListeningAndPlayback()

    // we need to start a new audio engine if the output device changed, so we might as well do it regardless
    let audioEngine = AVAudioEngine()
    self.audioEngine = audioEngine

    try await setupAudioPlayback(audioEngine)
    try setupVoiceProcessing(audioEngine)

    do {
      try audioEngine.start()
    } catch {
      throw ApplicationError("Failed to start audio engine: \(error.localizedDescription)")
    }

    try await setupMicrophone(audioEngine)
  }

  private func setupMicrophone(_ engine: AVAudioEngine) async throws {
    let microphone = Microphone(engine: engine)
    self.microphone = microphone

    microphone.start()

    let micFormat = engine.inputNode.outputFormat(forBus: 0)
    guard let converter = AVAudioConverter(from: micFormat, to: modelInputFormat) else {
      throw ApplicationError("Failed to create audio converter")
    }

    listenTask = Task {
      for await audio in microphone.audio {
        try microphoneDataQueue.yield(converter.convertBuffer(audio))
      }
    }
  }

  private func setupAudioPlayback(_ engine: AVAudioEngine) async throws {
    let playbackFormat = engine.outputNode.outputFormat(forBus: 0)
    audioPlayer = try AudioPlayer(
      engine: engine,
      inputFormat: modelOutputFormat,
      outputFormat: playbackFormat
    )
  }

  /// Sets up the voice processing I/O, if it needs to be setup.
  private func setupVoiceProcessing(_ engine: AVAudioEngine) throws {
    do {
      let headphonesConnected = headphonesConnected()
      let vpEnabled = engine.inputNode.isVoiceProcessingEnabled

      if !vpEnabled, !headphonesConnected {
        try engine.inputNode.setVoiceProcessingEnabled(true)
      } else if headphonesConnected, vpEnabled {
        // bluetooth headphones have integrated AEC, so if we don't disable VP IO we get muted output
        try engine.inputNode.setVoiceProcessingEnabled(false)
      }
    } catch {
      throw ApplicationError("Failed to enable voice processing: \(error.localizedDescription)")
    }
  }

  /// When the output device changes, ensure the audio playback and recording classes are properly restarted.
  private func listenForRouteChange() {
    routeTask?.cancel()
    routeTask = Task { [weak self] in
      for await notification in NotificationCenter.default.notifications(
        named: AVAudioSession.routeChangeNotification
      ) {
        await self?.handleRouteChange(notification: notification)
      }
    }
  }

  private func handleRouteChange(notification: Notification) {
    guard let userInfo = notification.userInfo,
      let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
      let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
      return
    }

    switch reason {
    case .newDeviceAvailable, .oldDeviceUnavailable:
      Task { @MainActor in
        do {
          try await spawnAudioProcessingThread()
        } catch {
          await logger
            .error("Failed to spawn audio processing thread: \(String(describing: error))")
        }
      }
    default: ()
    }
  }

  /// Checks if the current audio route is a a headphone.
  ///
  /// This includes airpods.
  private func headphonesConnected() -> Bool {
    return AVAudioSession.sharedInstance().currentRoute.outputs.contains {
      headphonePortTypes.contains($0.portType)
    }
  }
}
