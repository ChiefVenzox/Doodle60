//
//  GalleryView.swift
//  Doodle60
//

import SwiftUI
import UIKit

struct GalleryView: View {
    @EnvironmentObject private var appState: AppState

    @State private var items: [GalleryItem] = []
    @State private var searchText = ""
    @State private var shareURL: URL? = nil
    @State private var isSharePresented = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    private var filteredItems: [GalleryItem] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return items }
        return items.filter { $0.prompt.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        Text("^[\(items.count) drawing](inflect: true) saved")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 4)
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(filteredItems) { item in
                                GalleryCard(item: item) {
                                    shareURL = item.url
                                    isSharePresented = true
                                } onDelete: {
                                    withAnimation { delete(item) }
                                }
                            }
                        }
                        .padding()

                        if filteredItems.isEmpty {
                            Text("No drawings match “\(searchText)”")
                                .foregroundStyle(.secondary)
                                .padding(.top, 40)
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search prompts")
                }
            }
            .navigationTitle("Gallery")
            .onAppear { items = ImageStore.loadAll() }
            .refreshable { items = ImageStore.loadAll() }
            .sheet(isPresented: $isSharePresented) {
                if let url = shareURL, let img = UIImage(contentsOfFile: url.path) {
                    ShareSheet(items: [img])
                } else {
                    ShareSheet(items: ["Doodle 60"])
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No drawings yet")
                .font(.system(.title3, design: .rounded)).bold()
            Text("Finish a 60-second round to see it show up here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                appState.selectedTab = .draw
            } label: {
                Label("Start Drawing", systemImage: "paintbrush.pointed.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, 4)
            Spacer()
            Spacer()
        }
    }

    private func delete(_ item: GalleryItem) {
        ImageStore.delete(url: item.url)
        items = ImageStore.loadAll()
        Haptics.impact(.light)
    }
}

private struct GalleryCard: View {
    let item: GalleryItem
    let onShare: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let ui = UIImage(contentsOfFile: item.url.path) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.card)
                    .frame(height: 160)
                    .overlay(Image(systemName: "photo").font(.title))
            }
            Text(item.prompt.isEmpty ? "—" : item.prompt)
                .font(.caption.weight(.medium))
                .lineLimit(1)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            Text(item.date, style: .date)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 4)
        }
        .padding(10)
        .glassCard(cornerRadius: 18)
        .onTapGesture { onShare() }
        .contextMenu {
            Button { onShare() } label: { Label("Share", systemImage: "square.and.arrow.up") }
            Button(role: .destructive, action: onDelete) { Label("Delete", systemImage: "trash") }
        }
    }
}

#Preview {
    GalleryView().environmentObject(AppState())
}
