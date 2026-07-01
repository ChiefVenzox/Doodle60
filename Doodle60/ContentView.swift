//
//  ContentView.swift
//  Doodle60
//
//  Created by Hakan Kaba on 11.08.2025.

import SwiftUI

// MARK: - Root
struct ContentView: View {
    @State private var showHome = false
    @AppStorage("forceDark") private var forceDark = false

    var body: some View {
        Group {
            if showHome {
                HomeView()
            } else {
                SplashView {
                    withAnimation(.spring()) { showHome = true }
                    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                        NotificationManager.prepareDailyReminder()
                    }
                }
            }
        }
        .preferredColorScheme(forceDark ? .dark : nil)
    }
}

#Preview {
    ContentView()
}
