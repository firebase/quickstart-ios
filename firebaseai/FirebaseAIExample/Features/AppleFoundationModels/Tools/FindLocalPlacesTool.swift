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
import FoundationModels
import FirebaseAILogic

@available(iOS 26.0, *)
@Generable
public struct PlacesResponse: Codable {
    public let places: [String]
}

@available(iOS 26.0, *)
@Generable
public struct ToolResult: Codable {
    public let summary: String
    public let attributions: [Attribution]
}

@available(iOS 26.0, *)
public final class FindLocalPlacesTool {
    public let name = "findLocalPlaces"
    public let description = "Finds points of interest and local businesses matching a query for a specified destination."
    
    public init() {}

    @available(iOS 26.0, *)
    @Generable
    public struct Arguments {
        @Guide(description: "The destination city/place to look up for (e.g. 'Paris', 'New York').")
        public let destination: String

        @Guide(description: "The category or query to search (e.g. 'hotels', 'Italian restaurants', 'museums').")
        public let category: String
    }
    
    public func call(arguments: Arguments) async throws -> ToolResult {
        print("FindLocalPlacesTool: call called with destination: \(arguments.destination), category: \(arguments.category)")
        
        // Setup Firebase AI with Google Maps grounding
        let ai = FirebaseAI.firebaseAI(backend: .vertexAI(location: "global"))
        let session = ai.generativeModelSession(
            model: "gemini-3.1-flash-lite",
            tools: [Tool.googleMaps()]
        )
        
        let prompt = "Find 3 real popular \(arguments.category) in \(arguments.destination). Use Google Maps to make sure the places are real and currently open."
        
        do {
            let response = try await session.respond(
                to: prompt,
                generating: PlacesResponse.self
            )
            
            var attributions: [Attribution] = []
            if let metadata = response.rawResponse.candidates.first?.groundingMetadata {
                for chunk in metadata.groundingChunks {
                    if let maps = chunk.maps, let title = maps.title, let url = maps.url?.absoluteString {
                        attributions.append(Attribution(title: title, url: url))
                    }
                }
            }
            
            let results = response.content.places
            print("FindLocalPlacesTool: found places: \(results.joined(separator: ", "))")
            
            return ToolResult(
                summary: "Here are some popular \(arguments.category) in \(arguments.destination): \(results.joined(separator: ", "))",
                attributions: attributions
            )
        } catch {
            print("FindLocalPlacesTool error: \(error.localizedDescription)")
            throw error
        }
    }
}

// Struct wrapper to conform to FoundationModels.Tool AND ToolRepresentable
@available(iOS 26.0, *)
public struct FindLocalPlacesToolWrapper: FoundationModels.Tool, ToolRepresentable, @unchecked Sendable {
    let tool: FindLocalPlacesTool
    
    public var name: String { tool.name }
    public var description: String { tool.description }
    
    public typealias Arguments = FindLocalPlacesTool.Arguments
    public typealias Output = ToolResult
    
    public func call(arguments: Arguments) async throws -> ToolResult {
        try await tool.call(arguments: arguments)
    }
}
