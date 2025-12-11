// Copyright 2023 Google LLC
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

#if canImport(FirebaseAILogic)
    import FirebaseAILogic
#else
    import FirebaseAI
#endif
import SwiftUI

/// A view that displays a chat message that is grounded in Google Search.
struct GroundedResponseView: View {
    var message: ChatMessage
    var groundingMetadata: GroundingMetadata

    var body: some View {
        // We can only display a response grounded in Google Search if the searchEntrypoint is non-nil.
        let isCompliant = (groundingMetadata.groundingChunks.isEmpty || groundingMetadata
            .searchEntryPoint != nil)
        if isCompliant {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    // Message text
                    ResponseTextView(message: message)

                    if !groundingMetadata.groundingChunks.isEmpty {
                        Divider()
                        // Source links
                        ForEach(0 ..< groundingMetadata.groundingChunks.count, id: \.self) { index in
                            if let webChunk = groundingMetadata.groundingChunks[index].web {
                                SourceLinkView(
                                    title: webChunk.title ?? "Untitled Source",
                                    uri: webChunk.uri
                                )
                            }
                        }
                    }
                    // Search suggestions
                    if let searchEntryPoint = groundingMetadata.searchEntryPoint {
                        Divider()
                        GoogleSearchSuggestionView(htmlString: searchEntryPoint.renderedContent)
                            .frame(height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// A  view for a single, clickable source link.
struct SourceLinkView: View {
    let title: String
    let uri: String?

    var body: some View {
        if let uri, let url = URL(string: uri) {
            Link(destination: url) {
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(title)
                        .font(.footnote)
                        .underline()
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                }
            }
            .buttonStyle(.plain)
        }
    }
}
