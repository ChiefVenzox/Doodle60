//
//  ResultView.swift
//  Doodle60
//
//  Shown right after a drawing is saved: celebrate, share, or go again.
//

import SwiftUI
import UIKit

struct ResultView: View {
    let image: UIImage
    let prompt: String
    let onDrawAgain: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isSharePresented = false
    @State private var appear = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text("Nice work! 🎉")
                    .font(.system(.title, design: .rounded)).bold()

                Text(prompt)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(.separator, lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
                    .padding(.horizontal)
                    .scaleEffect(appear ? 1 : 0.9)
                    .opacity(appear ? 1 : 0)

                Spacer(minLength: 0)

                HStack(spacing: 12) {
                    Button {
                        isSharePresented = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button {
                        Haptics.impact(.medium)
                        dismiss()
                        onDrawAgain()
                    } label: {
                        Label("Draw Again", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $isSharePresented) {
                ShareSheet(items: [image])
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { appear = true }
                Haptics.notify(.success)
            }
        }
    }
}
