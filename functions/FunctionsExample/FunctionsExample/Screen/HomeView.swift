//
//  HomeView.swift
//  FunctionsExample
//
//  Created by Gran Luo on 1/12/22.
//

import SwiftUI

struct HomeView: View {
  var body: some View {
    VStack {
      AddNumbers()
      AddMessage()
      Spacer()
    }
  }
}

struct HomeView_Previews: PreviewProvider {
  static var previews: some View {
    HomeView()
  }
}
