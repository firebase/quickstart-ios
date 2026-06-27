// Copyright 2026 Google LLC
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
import SwiftUI
import Combine
import FoundationModels
import FirebaseAILogic

@available(iOS 27.0, *)
@MainActor
public final class AppleAIViewModel: ObservableObject {
    // Shared state
    @Published public var inProgress = false
    @Published public var error: Error?
    
    // Feature 1: Hybrid Summary/Translation
    @Published public var inputText: String = "It is the quintessential autumn harvest fruit, famously baked into warm cinnamon pastries, dipped in sticky caramel on Halloween, and traditionally rumored to keep medical professionals at bay if eaten once a day."
    @Published public var outputSummary: TextSummary?
    @Published public var isUsingLocalModel: Bool = false
    
    // Feature 2: Smart Planner
    @Published public var destination: String = "San Francisco"
    @Published public var interests: String = "tech history, good coffee, bay views"
    @Published public var itinerary: Itinerary.PartiallyGenerated?
    
    // Feature 3: Visual Identifier
    @Published public var selectedImage: UIImage?
    @Published public var identifiedObject: IdentifiedObject?
    
    @Published public var forceCloudModel: Bool = false
    
    private var activeTask: Task<Void, Never>?
    
    public init() {}
    
    public func stopActiveTask() {
        activeTask?.cancel()
        activeTask = nil
        inProgress = false
    }
    
    // MARK: - Feature 1: Hybrid Summary/Translation
    public func runSummarization() async {
        stopActiveTask()
        inProgress = true
        error = nil
        outputSummary = nil
        
        activeTask = Task {
            defer { self.inProgress = false }
            
            let instructions = Instructions {
                "Your job is to summarize the provided text in exactly 2 bullet points."
            }
            
            let availability = SystemLanguageModel.default.availability
            
            // Try local model first if it reports available and not forced to cloud
            if !forceCloudModel && availability == .available {
                isUsingLocalModel = true
                do {
                    let session = LanguageModelSession(
                        model: SystemLanguageModel.default,
                        instructions: instructions
                    )
                    let response = try await session.respond(to: inputText, generating: TextSummary.self)
                    if !Task.isCancelled {
                        self.outputSummary = response.content
                    }
                    return
                } catch {
                    // Fall back to cloud model if local model fails (e.g. assets not downloaded on simulator)
                    if error.isMLAssetUnavailable {
                        print("Local ML assets unavailable. Falling back to cloud model...")
                    } else {
                        print("Local model failed: \(error.localizedDescription). Falling back to cloud model...")
                    }
                }
            }
            
            // Fallback to cloud model
            isUsingLocalModel = false
            do {
                let ai = FirebaseAI.firebaseAI(backend: .vertexAI(location: "global"))
                let model = ai.geminiLanguageModel(name: "gemini-3.1-flash-lite")
                let session = LanguageModelSession(
                    model: model,
                    instructions: instructions
                )
                let response = try await session.respond(to: inputText, generating: TextSummary.self)
                if !Task.isCancelled {
                    self.outputSummary = response.content
                }
            } catch {
                if !Task.isCancelled {
                    // If even the cloud model via LanguageModelSession fails (likely due to missing guardrail assets),
                    // we show a descriptive error message.
                    if let mlMessage = error.mlAssetErrorMessage {
                        print("ML Asset Error detected in cloud fallback: \(mlMessage)")
                        // We can either set the error here or try one last direct fallback.
                        // Let's set a custom error that wraps the message.
                        self.error = NSError(domain: "FirebaseAIExample", 
                                             code: 1, 
                                             userInfo: [NSLocalizedDescriptionKey: mlMessage])
                    } else {
                        self.error = error
                    }
                }
            }
        }
    }
    
    // MARK: - Feature 2: Smart Planner
    public func generateItinerary() async {
        stopActiveTask()
        inProgress = true
        error = nil
        itinerary = nil
        isUsingLocalModel = false
        
        activeTask = Task {
            defer { self.inProgress = false }
            
            let localPlacesTool = FindLocalPlacesToolWrapper(tool: FindLocalPlacesTool())
            let instructions = Instructions {
                "Your job is to create a structured 1-day itinerary for the user."
                "Ensure you use the findLocalPlaces tool to search for real places and recommendations in the destination city."
            }
            let promptText = "Generate a structured 1-day itinerary for \(destination) focused on \(interests). Include exactly 3 activities (morning, afternoon, evening) with real recommendations. For any place returned by the findLocalPlaces tool, populate the 'attributions' array in the response with the exact name (title) and Google Maps URL (url) returned by the tool."
            
            let availability = SystemLanguageModel.default.availability
            
            // Try local model first if it reports available and not forced to cloud
            if !forceCloudModel && availability == .available {
                isUsingLocalModel = true
                do {
                    let session = LanguageModelSession(
                        model: SystemLanguageModel.default,
                        tools: [localPlacesTool],
                        instructions: instructions
                    )
                    let stream = session.streamResponse(
                        to: promptText,
                        generating: Itinerary.self
                    )
                    for try await response in stream {
                        if Task.isCancelled { break }
                        self.itinerary = response.content
                        print(response.content)
                    }
                    return
                } catch {
                    // Fall back to cloud model if local model fails (e.g. assets not downloaded on simulator)
                    if error.isMLAssetUnavailable {
                        print("Local ML assets unavailable for Planner. Falling back to cloud model...")
                    } else {
                        print("Local model failed for Planner: \(error.localizedDescription). Falling back to cloud model...")
                    }
                }
            }
            
            // Fallback to cloud model
            isUsingLocalModel = false
            do {
                let ai = FirebaseAI.firebaseAI(backend: .vertexAI(location: "global"))
                let model = ai.geminiLanguageModel(
                    name: "gemini-3.5-flash"
                )
                let session = LanguageModelSession(
                    model: model,
                    tools: [localPlacesTool],
                    instructions: instructions
                )
                let stream = session.streamResponse(
                    to: promptText,
                    generating: Itinerary.self
                )
                for try await response in stream {
                    if Task.isCancelled { break }
                    self.itinerary = response.content
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error
                }
            }
        }
    }
    
    // MARK: - Feature 3: Visual Identifier
    public func identifySelectedImage() async {
        guard let image = selectedImage else { return }
        stopActiveTask()
        inProgress = true
        error = nil
        identifiedObject = nil
        isUsingLocalModel = false
        
        activeTask = Task {
            defer { self.inProgress = false }
            
            guard let cgImage = image.cgImage,
                  let imageData = image.jpegData(compressionQuality: 0.8) else { return }
            
            let instructions = Instructions {
                "You are a visual object identifier."
            }
            
            let availability = SystemLanguageModel.default.availability
            
            // Try local model first if it reports available and not forced to cloud
            if !forceCloudModel && availability == .available {
                isUsingLocalModel = true
                do {
                    let session = LanguageModelSession(
                        model: SystemLanguageModel.default,
                        instructions: instructions
                    )
                    let response = try await session.respond(
                        generating: IdentifiedObject.self
                    ) {
                        "Identify the primary object in this image. Be as specific as possible, categorize it, and provide a short 2-sentence description."
                        Attachment(cgImage)
                    }
                    if !Task.isCancelled {
                        self.identifiedObject = response.content
                    }
                    return
                } catch {
                    // Fall back to cloud model if local model fails (e.g. assets not downloaded on simulator)
                    if error.isMLAssetUnavailable {
                        print("Local ML assets unavailable for Vision ID. Falling back to cloud model...")
                    } else {
                        print("Local model failed for Vision ID: \(error.localizedDescription). Falling back to cloud model...")
                    }
                }
            }
            
            // Fallback to cloud model
            isUsingLocalModel = false
            do {
                let ai = FirebaseAI.firebaseAI(backend: .vertexAI(location: "global"))
                let model = ai.geminiLanguageModel(name: "gemini-3.5-flash")
                let session = LanguageModelSession(
                    model: model,
                    instructions: instructions
                )
                let response = try await session.respond(
                    generating: IdentifiedObject.self
                ) {
                    "Identify the primary object in this image. Be as specific as possible, categorize it, and provide a short 2-sentence description."
                    InlineDataPart(data: imageData, mimeType: "image/jpeg")
                }
                
                if !Task.isCancelled {
                    self.identifiedObject = response.content
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error
                }
            }
        }
    }
}
