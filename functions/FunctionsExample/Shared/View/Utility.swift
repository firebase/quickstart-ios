//
//  Utility.swift
//  FunctionsExample
//
//  Created by Gran Luo on 3/18/22.
//

import Foundation
import SwiftUI

struct Utility {
#if os(iOS)
  let textForegroundColor = Color(UIColor.secondaryLabel)
  let roundRectangleFillColor = Color(.secondarySystemBackground)
#elseif os(macOS)
  let textForegroundColor = Color(NSColor.secondaryLabelColor)
  let roundRectangleFillColor = Color(NSColor.systemGray)
#elseif os(tvOS)
  let textForegroundColor = Color.secondary
  let roundRectangleFillColor = Color.gray
#endif
}
