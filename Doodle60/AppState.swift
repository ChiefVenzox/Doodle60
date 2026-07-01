//
//  AppState.swift
//  Doodle60
//
//  Shared app-wide state (e.g. cross-tab navigation).
//

import SwiftUI

final class AppState: ObservableObject {
    enum Tab: Hashable {
        case draw, gallery, settings
    }

    @Published var selectedTab: Tab = .draw
}
