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

import SwiftUI
import PhotosUI
import FoundationModels
import FirebaseAILogic

@available(iOS 27.0, *)
struct AppleAIScreen: View {
    @StateObject private var viewModel = AppleAIViewModel()
    @State private var selectedTab = 0
    @State private var photosPickerItem: PhotosPickerItem? = nil
    @State private var presentErrorDetails = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Feature", selection: $selectedTab) {
                    Text("Hybrid AI").tag(0)
                    Text("Planner").tag(1)
                    Text("Vision ID").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // Content Views
                ScrollView {
                    VStack(spacing: 20) {
                        if selectedTab == 0 {
                            hybridAIView
                        } else if selectedTab == 1 {
                            plannerView
                        } else {
                            visionIDView
                        }
                    }
                    .padding()
                }
            }
            
            if viewModel.inProgress {
                ProgressOverlay()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Apple Intelligence")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.inProgress {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Stop") {
                        viewModel.stopActiveTask()
                    }
                }
            }
        }
        .sheet(isPresented: $presentErrorDetails) {
            if let error = viewModel.error {
                ErrorDetailsView(error: error)
            }
        }
        .onChange(of: viewModel.error != nil) { oldValue, newValue in
            if newValue {
                presentErrorDetails = true
            }
        }
    }
    
    // MARK: - Subviews
    
    // Feature 1: Hybrid AI
    private var hybridAIView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Input Text")
                    .font(.headline)
                TextEditor(text: $viewModel.inputText)
                    .frame(height: 120)
                    .padding(4)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(8)
            }
            
            Button(action: {
                Task {
                    await viewModel.runSummarization()
                }
            }) {
                HStack {
                    Spacer()
                    Image(systemName: "sparkles")
                    Text("Summarize with Apple SDK")
                    Spacer()
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .disabled(viewModel.inProgress)
            
            if let summary = viewModel.outputSummary {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Summary Points")
                            .font(.headline)
                        Spacer()
                        
                        // Badge indicating where it was executed
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.isUsingLocalModel ? "iphone" : "cloud.fill")
                            Text(viewModel.isUsingLocalModel ? "Local (Apple)" : "Cloud (Gemini)")
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(viewModel.isUsingLocalModel ? Color.green.opacity(0.2) : Color.purple.opacity(0.2))
                        .foregroundColor(viewModel.isUsingLocalModel ? .green : .purple)
                        .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(summary.summaryPoints, id: \.self) { point in
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                    .bold()
                                Text(point)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                }
                .transition(.opacity.combined(with: .slide))
            }
        }
    }
    
    // Feature 2: Planner View
    private var plannerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 12) {
                HStack {
                    Text("Destination")
                        .frame(width: 100, alignment: .leading)
                    TextField("e.g. Paris, Tokyo", text: $viewModel.destination)
                        .textFieldStyle(.roundedBorder)
                }
                HStack {
                    Text("Interests")
                        .frame(width: 100, alignment: .leading)
                    TextField("e.g. art, cafes, parks", text: $viewModel.interests)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
            
            Button(action: {
                Task {
                    await viewModel.generateItinerary()
                }
            }) {
                HStack {
                    Spacer()
                    Image(systemName: "map.fill")
                    Text("Create Itinerary Plan")
                    Spacer()
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .disabled(viewModel.inProgress)
            
            if let itinerary = viewModel.itinerary {
                VStack(alignment: .leading, spacing: 12) {
                    Text(itinerary.title ?? "Generating plan...")
                        .font(.title3)
                        .bold()
                    
                    if let desc = itinerary.description {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let rationale = itinerary.rationale {
                        Text("Rationale: \(rationale)")
                            .font(.caption)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Day Plans
                    if let days = itinerary.days {
                        ForEach(days, id: \.title) { day in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(day.title ?? "Day Plan")
                                    .font(.headline)
                                    .padding(.top, 4)
                                
                                if let activities = day.activities {
                                    ForEach(activities, id: \.title) { activity in
                                        HStack(alignment: .top, spacing: 12) {
                                            Image(systemName: getSymbol(for: activity.type))
                                                .foregroundColor(.blue)
                                                .frame(width: 24, height: 24)
                                                .background(Color.blue.opacity(0.1))
                                                .cornerRadius(6)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(activity.title ?? "Activity")
                                                    .font(.subheadline)
                                                    .bold()
                                                if let desc = activity.description {
                                                    Text(desc)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                                if let lat = activity.latitude, let lon = activity.longitude {
                                                    Text(String(format: "Location: %.4f, %.4f", lat, lon))
                                                        .font(.system(.caption, design: .monospaced))
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                        }
                    }
                    
                    if let attributions = itinerary.attributions, !attributions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sources & Maps Links")
                                .font(.headline)
                            
                            ForEach(attributions, id: \.url) { attribution in
                                if let urlString = attribution.url, let url = URL(string: urlString), let title = attribution.title {
                                    Link(destination: url) {
                                        HStack {
                                            Image(systemName: "mappin.and.ellipse")
                                            Text(title)
                                                .underline()
                                            Spacer()
                                        }
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }
    
    // Feature 3: Vision ID View
    private var visionIDView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select or Snap a Photo to Identify")
                .font(.headline)
            
            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                VStack(spacing: 12) {
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 40))
                            Text("Select an Image")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                }
            }
            .onChange(of: photosPickerItem) { oldItem, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.selectedImage = image
                        await viewModel.identifySelectedImage()
                    }
                }
            }
            
            if let identified = viewModel.identifiedObject {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Identification Result")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Name:")
                                .bold()
                            Text(identified.name)
                        }
                        HStack {
                            Text("Category:")
                                .bold()
                            Text(identified.category)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description:")
                                .bold()
                            Text(identified.description)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(10)
                }
                .transition(.opacity)
            }
        }
    }
    
    // Helper to pick icons for activity kinds
    private func getSymbol(for kind: ActivityKind?) -> String {
        guard let kind = kind else { return "info.circle" }
        switch kind {
        case .sightseeing: return "binoculars.fill"
        case .foodAndDining: return "fork.knife"
        case .shopping: return "bag.fill"
        case .hotelAndLodging: return "bed.double.fill"
        }
    }
}
