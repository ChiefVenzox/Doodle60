//
//  GameView.swift
//  Doodle60
//
//  60-second drawing round backed by PencilKit.
//

import SwiftUI
#if os(iOS)
import PencilKit
#endif
import UIKit

struct GameView: View {
    @State private var prompt: String = WordProvider.random()
    @State private var dailyMode = true
    @State private var manualPromptOverride = false

    @State private var canvasView: PKCanvasView? = nil
    @StateObject private var timer = CountdownTimer(duration: 60)

    @State private var savedImage: UIImage?
    @State private var isResultPresented = false

    private var difficulty: Difficulty { WordProvider.difficulty(of: prompt) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                promptCard

                // Canvas
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Theme.card)
                    PKCanvasRepresentable(canvasView: $canvasView)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.separator, lineWidth: 0.5)
                )
                .overlay(alignment: .bottomTrailing) {
                    Text(timer.isRunning ? "Draw!" : "Ready?")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Theme.glass, in: Capsule())
                        .padding(10)
                }
                .overlay(alignment: .topLeading) { undoRedoControls }
                .padding(.horizontal)

                controlsRow
            }
            .padding(.top, 8)
            .navigationTitle("Draw (60s)")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    StreakBadge()
                }
            }
            .onAppear {
                timer.onExpire = { endAndSave() }
                timer.onTick = { remaining in
                    if [3, 2, 1].contains(remaining) { Haptics.notify(.warning) }
                }
            }
            .fullScreenCover(isPresented: $isResultPresented) {
                if let savedImage {
                    ResultView(image: savedImage, prompt: prompt, onDrawAgain: start)
                }
            }
        }
    }

    // MARK: - Subviews
    private var promptCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(prompt)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(spacing: 6) {
                    Circle()
                        .fill(Theme.difficultyColor(difficulty))
                        .frame(width: 8, height: 8)
                    Text(difficulty.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            CountdownRing(progress: timer.progress, timeLeft: timer.timeLeft, isRunning: timer.isRunning)

            Toggle("Daily", isOn: $dailyMode)
                .labelsHidden()
                .toggleStyle(.switch)
                .disabled(timer.isRunning)
        }
        .padding(12)
        .glassCard(cornerRadius: 18)
        .padding(.horizontal)
    }

    private var undoRedoControls: some View {
        HStack(spacing: 8) {
            Button {
                canvasView?.undoManager?.undo()
                Haptics.impact(.light)
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(Theme.glass, in: Circle())
            }
            Button {
                canvasView?.undoManager?.redo()
                Haptics.impact(.light)
            } label: {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(Theme.glass, in: Circle())
            }
        }
        .foregroundStyle(.primary)
        .padding(10)
    }

    private var controlsRow: some View {
        HStack(spacing: 12) {
            Button {
                changePromptKeepingTimer()
            } label: {
                Label("Change Word", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(timer.isRunning)

            Button { clearCanvas() } label: {
                Label("Clear", systemImage: "eraser")
            }
            .buttonStyle(TertiaryButtonStyle())

            Spacer()

            Button {
                if timer.isRunning { endAndSave() } else { start() }
            } label: {
                Label(timer.isRunning ? "Save" : "Start", systemImage: timer.isRunning ? "checkmark.circle.fill" : "play.circle.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Actions
    private func start() {
        clearCanvas()
        if !manualPromptOverride {
            prompt = dailyMode ? DailyWordProvider.todayWord() : WordProvider.random()
        }
        manualPromptOverride = false
        Haptics.impact(.medium)
        timer.start()
    }

    private func clearCanvas() {
        canvasView?.drawing = PKDrawing()
    }

    private func endAndSave() {
        timer.stop()
        guard let canvas = canvasView else { return }
        let bounds = canvas.bounds
        let scale = canvas.window?.screen.scale ?? UIScreen.main.scale
        let uiImage = canvas.drawing.image(from: bounds, scale: scale)
        ImageStore.save(image: uiImage, prompt: prompt)
        StatsStore.recordDrawing()
        savedImage = uiImage
        isResultPresented = true
    }

    private func changePromptKeepingTimer() {
        prompt = WordProvider.random()
        manualPromptOverride = true
        Haptics.impact(.light)
    }
}

#if os(iOS)
// MARK: - PencilKit Bridge (UIKit in SwiftUI)

/// A canvas that attaches its own tool picker once it lands in a window.
/// Doing this in `didMoveToWindow` (instead of the SwiftUI `onAppear`) is what
/// actually makes the picker show up: at `onAppear` time the view isn't in a
/// window yet, so `becomeFirstResponder` silently fails.
final class ToolPickerCanvasView: PKCanvasView {
    private let toolPicker = PKToolPicker()

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        toolPicker.setVisible(true, forFirstResponder: self)
        toolPicker.addObserver(self)
        becomeFirstResponder()
    }
}

struct PKCanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView?

    func makeUIView(context: Context) -> ToolPickerCanvasView {
        let canvas = ToolPickerCanvasView()
        canvas.backgroundColor = .systemBackground
        canvas.drawingPolicy = .anyInput
        canvas.isOpaque = true
        DispatchQueue.main.async { self.canvasView = canvas }
        return canvas
    }

    func updateUIView(_ uiView: ToolPickerCanvasView, context: Context) { }
}
#endif

#Preview {
    GameView()
}
