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

@available(iOS 26.0, *)
@Generable
public struct Itinerary: Equatable, Codable {
    @Guide(description: "An exciting name for the trip.")
    public let title: String
    
    @Guide(description: "The name of the destination.")
    public let destinationName: String
    
    @Guide(description: "A brief, catchy description of the trip.")
    public let description: String
    
    @Guide(description: "An explanation of why this plan fits the user's request.")
    public let rationale: String
    
    @Guide(description: "A list of day plans.")
    public let days: [DayPlan]
    
    @Guide(description: "Any source attributions or links for the recommended places.")
    public let attributions: [Attribution]?
}

@available(iOS 26.0, *)
@Generable
public struct Attribution: Equatable, Codable {
    public let title: String
    public let url: String
}

@available(iOS 26.0, *)
@Generable
public struct DayPlan: Equatable, Codable {
    @Guide(description: "A unique title for this day.")
    public let title: String
    
    public let subtitle: String
    
    @Guide(description: "A list of activities planned for this day.")
    public let activities: [Activity]
}

@available(iOS 26.0, *)
@Generable
public struct Activity: Equatable, Codable {
    public let type: ActivityKind
    public let title: String
    public let description: String
    public let latitude: Double?
    public let longitude: Double?
}

@available(iOS 26.0, *)
@Generable
public enum ActivityKind: String, Codable {
    case sightseeing
    case foodAndDining
    case shopping
    case hotelAndLodging
    
    public var displayName: String {
        switch self {
        case .sightseeing: return "Sightseeing"
        case .foodAndDining: return "Food & Dining"
        case .shopping: return "Shopping"
        case .hotelAndLodging: return "Hotel & Lodging"
        }
    }
}

@available(iOS 26.0, *)
@Generable
public struct IdentifiedObject: Equatable, Codable {
    @Guide(description: "The name of the primary object or landmark detected.")
    public let name: String
    
    @Guide(description: "The category of the object (e.g. Landmark, Plant, Food, Animal, Device, Clothing).")
    public let category: String
    
    @Guide(description: "A short, 2-sentence description of the object and interesting facts.")
    public let description: String
}

@available(iOS 26.0, *)
@Generable
public struct TextSummary: Equatable, Codable {
    @Guide(description: "A list of exactly 2 key summary points.")
    public let summaryPoints: [String]
}
