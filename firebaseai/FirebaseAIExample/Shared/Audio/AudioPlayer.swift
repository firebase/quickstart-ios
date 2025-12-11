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
import Foundation
import OSLog

/// Plays back audio through the primary output device.
class AudioPlayer {
    private var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "generative-ai")

    private let engine: AVAudioEngine
    private let inputFormat: AVAudioFormat
    private let outputFormat: AVAudioFormat
    private let playbackNode: AVAudioPlayerNode
    private var formatConverter: AVAudioConverter

    init(engine: AVAudioEngine, inputFormat: AVAudioFormat, outputFormat: AVAudioFormat) throws {
        self.engine = engine

        guard let formatConverter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            throw ApplicationError("Failed to create the audio converter")
        }

        let playbackNode = AVAudioPlayerNode()

        engine.attach(playbackNode)
        engine.connect(playbackNode, to: engine.mainMixerNode, format: outputFormat)

        self.inputFormat = inputFormat
        self.outputFormat = outputFormat
        self.formatConverter = formatConverter
        self.playbackNode = playbackNode
    }

    deinit {
        stop()
    }

    /// Queue audio to be played through the output device.
    ///
    /// Note that in a real app, you'd ideally schedule the data before converting it, and then mark data as consumed after its been played
    /// back. That way, if the audio route changes during playback, you can requeue the buffer on the new output device.
    ///
    /// For the sake of simplicity, that is not implemented here; a route change will prevent the currently queued conversation from
    /// being played through the output device.
    public func play(_ audio: Data) throws {
        guard engine.isRunning else {
            logger.warning("Audio engine needs to be running to play audio.")
            return
        }

        guard let inputBuffer = try AVAudioPCMBuffer.fromInterleavedData(
            data: audio,
            format: inputFormat
        ) else {
            throw ApplicationError("Failed to create input buffer for playback")
        }

        let buffer = try formatConverter.convertBuffer(inputBuffer)

        playbackNode.scheduleBuffer(buffer, at: nil)
        playbackNode.play()
    }

    /// Stops the current audio playing.
    public func interrupt() {
        playbackNode.stop()
    }

    /// Permanently stop all audio playback.
    public func stop() {
        interrupt()
        engine.disconnectNodeInput(playbackNode)
        engine.disconnectNodeOutput(playbackNode)
    }
}
