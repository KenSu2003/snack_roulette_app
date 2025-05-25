//
//  ContentView.swift
//  Midnight Snack Roulette
//
//  Created by Ken Su on 5/25/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        WheelViewControllerWrapper()
            .edgesIgnoringSafeArea(.all)
    }
}

struct WheelViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> WheelViewController {
        return WheelViewController()
    }
    func updateUIViewController(_ uiViewController: WheelViewController, context: Context) {}
}

#Preview {
    ContentView()
}
