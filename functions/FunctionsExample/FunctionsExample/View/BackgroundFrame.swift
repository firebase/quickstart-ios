//
//  BackgroundFrame.swift
//  FunctionsExample
//
//  Created by Gran Luo on 1/12/22.
//

import SwiftUI

struct BackgroundFrame: View {
    var body: some View {
      RoundedRectangle(cornerRadius: 25)
        .fill(Color.white)
          .frame(width: ScreenDimensions.width * 0.95, height: 200)
          .shadow(color: Color(.black), radius: 5, x: 3, y: 1)
    }
}

struct BackgroundFrame_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundFrame()
    }
}

class ScreenDimensions {
    static var width: CGFloat = UIScreen.main.bounds.size.width
    static var height: CGFloat = UIScreen.main.bounds.size.height
}
