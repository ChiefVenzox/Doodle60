//
//  SettingsView.swift
//  Doodle60
//

import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @AppStorage("forceDark") private var forceDark = false
    @AppStorage("reminder_enabled") private var reminderEnabled = true

    @State private var date = Calendar.current.date(
        from: DateComponents(
            hour: NotificationManager.reminderHourMinute().hour,
            minute: NotificationManager.reminderHourMinute().minute
        )
    ) ?? Date()

    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isSavedBannerShown = false
    @State private var isResetConfirmationShown = false
    @State private var galleryCount = ImageStore.loadAll().count

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Toggle(isOn: $forceDark) {
                        Label("Dark Mode", systemImage: "moon.fill")
                    }
                }

                Section {
                    Toggle(isOn: reminderBinding) {
                        Label("Daily Reminder", systemImage: "bell.fill")
                    }

                    if reminderEnabled {
                        DatePicker("Time", selection: $date, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)

                        Button {
                            saveReminderTime()
                        } label: {
                            Label("Save Time", systemImage: "checkmark.circle.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .listRowInsets(EdgeInsets())
                        .padding(.vertical, 4)

                        if isSavedBannerShown {
                            Label("Reminder time saved", systemImage: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }

                        if authorizationStatus == .denied {
                            deniedNotice
                        }
                    }
                } header: {
                    Text("Reminder")
                } footer: {
                    Text("We'll nudge you once a day to draw today's word.")
                }

                Section("Stats") {
                    HStack {
                        Label("Current streak", systemImage: "flame.fill")
                        Spacer()
                        Text("^[\(StatsStore.streak) day](inflect: true)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Total drawings", systemImage: "paintbrush.pointed.fill")
                        Spacer()
                        Text("\(StatsStore.totalDrawings)")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Gallery") {
                    HStack {
                        Label("Saved drawings", systemImage: "photo.stack")
                        Spacer()
                        Text("\(galleryCount)")
                            .foregroundStyle(.secondary)
                    }
                    Button(role: .destructive) {
                        isResetConfirmationShown = true
                    } label: {
                        Label("Clear Gallery", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                    .disabled(galleryCount == 0)
                }

                Section("About") {
                    Text("Doodle 60 — Draw today's word! 60 seconds 🖌️")
                        .foregroundStyle(.secondary)
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                refreshAuthorizationStatus()
                galleryCount = ImageStore.loadAll().count
            }
            .confirmationDialog(
                "Delete all saved drawings?",
                isPresented: $isResetConfirmationShown,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) {
                    ImageStore.deleteAll()
                    galleryCount = 0
                    Haptics.notify(.warning)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This can't be undone.")
            }
        }
    }

    private var reminderBinding: Binding<Bool> {
        Binding(
            get: { reminderEnabled },
            set: { newValue in
                reminderEnabled = newValue
                NotificationManager.setReminderEnabled(newValue)
                refreshAuthorizationStatus()
            }
        )
    }

    private var deniedNotice: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Notifications are disabled in system settings.", systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.caption.weight(.semibold))
        }
        .padding(.vertical, 2)
    }

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    private func saveReminderTime() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        NotificationManager.updateDailyReminder(hour: comps.hour ?? 9, minute: comps.minute ?? 0)
        Haptics.notify(.success)
        withAnimation { isSavedBannerShown = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { isSavedBannerShown = false }
        }
    }

    private func refreshAuthorizationStatus() {
        NotificationManager.checkAuthorizationStatus { status in
            authorizationStatus = status
        }
    }
}

#Preview {
    SettingsView()
}
