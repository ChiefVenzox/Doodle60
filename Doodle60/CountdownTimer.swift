//
//  CountdownTimer.swift
//  Doodle60
//
//  A reference-typed countdown so the underlying Combine timer is created
//  exactly once (via @StateObject) instead of being re-created every time a
//  SwiftUI view struct is re-initialized.
//

import Combine
import Foundation

@MainActor
final class CountdownTimer: ObservableObject {
    @Published private(set) var timeLeft: Int
    @Published private(set) var isRunning = false

    let duration: Int
    var onExpire: (() -> Void)?
    var onTick: ((Int) -> Void)?

    private var cancellable: AnyCancellable?

    init(duration: Int = 60) {
        self.duration = duration
        self.timeLeft = duration
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return Double(timeLeft) / Double(duration)
    }

    func start() {
        timeLeft = duration
        isRunning = true
        cancellable?.cancel()
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    func stop() {
        isRunning = false
        cancellable?.cancel()
        cancellable = nil
    }

    private func tick() {
        guard isRunning else { return }
        if timeLeft > 0 {
            timeLeft -= 1
            onTick?(timeLeft)
        }
        if timeLeft == 0 {
            stop()
            onExpire?()
        }
    }
}
