//
//  HomeView.swift
//  Doodle60
//

import SwiftUI

struct HomeView: View {
    @StateObject private var appState = AppState()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Theme.background(for: colorScheme).ignoresSafeArea()
            TabView(selection: $appState.selectedTab) {
                GameView()
                    .tabItem { Label("Draw", systemImage: "paintbrush.pointed.fill") }
                    .tag(AppState.Tab.draw)
                GalleryView()
                    .tabItem { Label("Gallery", systemImage: "photo.on.rectangle.angled") }
                    .tag(AppState.Tab.gallery)
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                    .tag(AppState.Tab.settings)
            }
        }
        .environmentObject(appState)
    }
}

#Preview {
    HomeView()
}
