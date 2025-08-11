//
//  ContentView.swift
//  Doodle60
//
//  Created by Hakan Kaba on 11.08.2025.


import SwiftUI
// PencilKit is only available on iOS; guard import for cross-platform builds
#if os(iOS)
import PencilKit
#endif
import UIKit
import UserNotifications

// MARK: - Theme & Styles
struct Theme {
    // Explicit gradient colors
    static let bgTop: Color = Color(UIColor.systemIndigo)
    static let bgBottom: Color = Color(UIColor.systemPurple)

    static let bg = LinearGradient(
        gradient: Gradient(colors: [bgTop, bgBottom]),
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let card = Color(.secondarySystemBackground)
    static let glass: Material = .ultraThin
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .lineLimit(1).minimumScaleFactor(0.8).labelStyle(.titleAndIcon)
            .foregroundStyle(.white)
            .frame(height: 65)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.accentColor)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let strokeWidth: CGFloat = configuration.isPressed ? 1.5 : 1.0
        return configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .lineLimit(1).minimumScaleFactor(0.8).labelStyle(.titleAndIcon)
            .foregroundStyle(.primary)
            .frame(height: 65)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.separator, lineWidth: strokeWidth)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .lineLimit(1).minimumScaleFactor(0.8).labelStyle(.titleAndIcon)
            .foregroundStyle(.primary)
            .frame(height: 65)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

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

// MARK: - Splash (in-app)
struct SplashView: View {
    let onFinish: () -> Void
    @State private var pulse = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "paintbrush.pointed")
                    .font(.system(size: 72))
                    .scaleEffect(pulse ? 1.0 : 0.85)
                    .opacity(pulse ? 1 : 0.6)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Doodle 60")
                        .font(.system(.largeTitle, design: .rounded)).bold()
                    Text("Draw, save, and smile in 60 seconds.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Theme.glass, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.separator, lineWidth: 0.5)
                )

                Button("Start") { onFinish() }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 10)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true }
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                NotificationManager.prepareDailyReminder()
            }
        }
    }
}

// MARK: - Home (Tab)
struct HomeView: View {
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            TabView {
                GameView()
                    .tabItem { Label("Draw", systemImage: "timer") }
                GalleryView()
                    .tabItem { Label("Gallery", systemImage: "photo.on.rectangle") }
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape") }
            }
        }
    }
}

struct SettingsView: View {
    @State private var date = Calendar.current.date(from: DateComponents(hour: NotificationManager.reminderHourMinute().hour, minute: NotificationManager.reminderHourMinute().minute)) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Toggle(isOn: .init(
                        get: { UserDefaults.standard.bool(forKey: "forceDark") },
                        set: { UserDefaults.standard.set($0, forKey: "forceDark") }
                    )) {
                        Label("Dark Mode", systemImage: "moon.fill")
                    }
                }
                Section("Reminder") {
                    DatePicker("Clock", selection: $date, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                    Button("Save") {
                        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                        NotificationManager.updateDailyReminder(hour: comps.hour ?? 9, minute: comps.minute ?? 0)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                Section("About") {
                    Text("Doodle 60 — Draw today's word! 60 seconds ")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Local Notifications (Daily reminder)
enum NotificationManager {
    static func prepareDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { ok, _ in
                    let hm = reminderHourMinute()
                    if ok { scheduleDaily(hour: hm.hour, minute: hm.minute) }
                }
            case .authorized, .provisional:
                let hm = reminderHourMinute()
                scheduleDaily(hour: hm.hour, minute: hm.minute)
            default:
                break
            }
        }
    }

    static func reminderHourMinute() -> (hour: Int, minute: Int) {
        let ud = UserDefaults.standard
        let h = ud.integer(forKey: "reminder_hour")
        let m = ud.integer(forKey: "reminder_minute")
        return (h == 0 && ud.object(forKey: "reminder_hour") == nil) ? (9, 0) : (h, m)
    }

    static func scheduleDaily(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dailyWordReminder"]) // reset

        var date = DateComponents()
        date.hour = hour
        date.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Doodle 60"
        content.body = "Draw today's word! 60 seconds 🖌️"
        content.sound = .default

        let request = UNNotificationRequest(identifier: "dailyWordReminder", content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }

    static func updateDailyReminder(hour: Int, minute: Int) {
        let ud = UserDefaults.standard
        ud.set(hour, forKey: "reminder_hour")
        ud.set(minute, forKey: "reminder_minute")
        scheduleDaily(hour: hour, minute: minute)
    }
}

// MARK: - Game Screen (60s + PencilKit)
struct GameView: View {
    @State private var prompt: String = WordProvider.random()
    @State private var timeLeft: Int = 60
    @State private var isRunning = false
    @State private var dailyMode = true
    @State private var manualPromptOverride = false

    @State private var canvasView: PKCanvasView? = nil
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Top bar
                HStack {
                    Text(prompt)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer()
                    Text("\(timeLeft)s")
                        .font(.system(.title2, design: .rounded).monospacedDigit())
                        .foregroundStyle(timeLeft <= 10 && isRunning ? .red : .primary)
                    Toggle("Daily", isOn: $dailyMode)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                .padding(.horizontal)

                // Canvas
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.card)
                    PKCanvasRepresentable(canvasView: $canvasView)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .overlay(
                    HStack {
                        Spacer()
                        VStack { Spacer()
                            Text(isRunning ? "Draw!" : "Ready?")
                                .font(.caption).padding(8)
                                .background(Theme.glass, in: Capsule())
                                .padding(8)
                        }
                    }
                )
                .padding(.horizontal)

                // Buttons
                HStack(spacing: 12) {
                    Button {
                        changePromptKeepingTimer()
                    } label: {
                        Label("Change Word", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    Button { clearCanvas() } label: {
                        Label("Clear", systemImage: "eraser")
                    }
                    .buttonStyle(TertiaryButtonStyle())
                    Spacer()
                    Button {
                        if isRunning { endAndSave() } else { start() }
                    } label: {
                        Label(isRunning ? "Save" : "Start", systemImage: isRunning ? "checkmark.circle.fill" : "play.circle.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("Draw (60s)")
            .onReceive(timer) { _ in
                guard isRunning else { return }
                if timeLeft > 0 { timeLeft -= 1 } else { endAndSave() }
                if [3,2,1].contains(timeLeft) {
                    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                        let gen = UINotificationFeedbackGenerator(); gen.notificationOccurred(.warning)
                    }
                }
            }
            .onAppear { showToolPickerIfPossible() }
        }
    }

    // Actions
    private func start() {
        clearCanvas()
        if !manualPromptOverride { // kullanıcı önceden kelimeyi değiştirmediyse varsayılanı ayarla
            prompt = dailyMode ? DailyWordProvider.todayWord() : WordProvider.random()
        }
        timeLeft = 60
        isRunning = true
        manualPromptOverride = false // start sonrası sıfırla
    }

    private func newRound() {
        isRunning = false
        start()
    }

    private func clearCanvas() {
        canvasView?.drawing = PKDrawing()
    }

    private func endAndSave() {
        isRunning = false
        guard let canvas = canvasView else { return }
        let bounds = canvas.bounds
        let scale = UIScreen.main.scale
        let uiImage = canvas.drawing.image(from: bounds, scale: scale)
        ImageStore.save(image: uiImage, prompt: prompt)
    }

    private func showToolPickerIfPossible() {
        guard let canvas = canvasView else { return }
        if let window = canvas.window, let picker = PKToolPicker.shared(for: window) {
            picker.setVisible(true, forFirstResponder: canvas)
            picker.addObserver(canvas)
            canvas.becomeFirstResponder()
        }
    }

    private func changePromptKeepingTimer() {
        // Sadece kelimeyi değiştir; süre ve çizim alanına dokunma
        prompt = WordProvider.random()
        manualPromptOverride = true
    }
}

#if os(iOS)
// MARK: - PencilKit Bridge (UIKit in SwiftUI)
struct PKCanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView?

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .systemBackground
        canvas.drawingPolicy = .anyInput
        canvas.isOpaque = true
        DispatchQueue.main.async { self.canvasView = canvas }
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) { }
}
#endif

// MARK: - Share Sheet (iOS)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) { }
}

// MARK: - Gallery
struct GalleryView: View {
    @State private var items: [GalleryItem] = []
    @State private var shareURL: URL? = nil
    @State private var isSharePresented = false
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            if let ui = UIImage(contentsOfFile: item.url.path) {
                                Image(uiImage: ui)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 160)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.card)
                                    .frame(height: 160)
                                    .overlay(Image(systemName: "photo").font(.title))
                            }
                            Text(item.prompt.isEmpty ? "—" : item.prompt)
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                        }
                        .padding(10)
                        .background(Theme.glass, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.separator, lineWidth: 0.5))
                        .onTapGesture {
                            shareURL = item.url
                            isSharePresented = true
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                ImageStore.delete(url: item.url)
                                items = ImageStore.loadAll()
                            } label: { Label("Delete", systemImage: "trash") }
                            Button {
                                shareURL = item.url
                                isSharePresented = true
                            } label: { Label("Share", systemImage: "square.and.arrow.up") }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                ImageStore.delete(url: item.url)
                                items = ImageStore.loadAll()
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Gallery")
            .onAppear { items = ImageStore.loadAll() }
            .refreshable { items = ImageStore.loadAll() }
            .sheet(isPresented: $isSharePresented) {
                if let url = shareURL, let img = UIImage(contentsOfFile: url.path) {
                    ShareSheet(items: [img])
                } else {
                    ShareSheet(items: ["Doodle 60"]) // fallback
                }
            }
        }
    }
}

// MARK: - Storage Helpers
struct GalleryItem: Identifiable {
    let id = UUID()
    let url: URL
    let prompt: String
}

enum ImageStore {
    private static var folderURL: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Gallery", isDirectory: true)
    }

    private static func ensureFolder() {
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
    }

    static func save(image: UIImage, prompt: String) {
        ensureFolder()
        let name = "\(timestamp())_\(slug(prompt)).png"
        let url = folderURL.appendingPathComponent(name)
        if let data = image.pngData() { try? data.write(to: url) }
    }

    static func loadAll() -> [GalleryItem] {
        ensureFolder()
        let urls = (try? FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)) ?? []
        let pngs = urls.filter { $0.pathExtension.lowercased() == "png" }
        return pngs.sorted { $0.lastPathComponent > $1.lastPathComponent }.map { url in
            let base = url.deletingPathExtension().lastPathComponent
            let parts = base.split(separator: "_", maxSplits: 1).map(String.init)
            let prompt = parts.count > 1 ? parts[1].replacingOccurrences(of: "-", with: " ") : ""
            return GalleryItem(url: url, prompt: prompt)
        }
    }

    static func delete(url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private static func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmmss"
        return f.string(from: Date())
    }

    private static func slug(_ s: String) -> String {
        let ascii = s.folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return String(ascii.unicodeScalars.filter { allowed.contains($0) })
    }
}

// MARK: - Words
enum WordProvider {
    static let easy: [String] = [
        "flying fish", "rocket snail", "pajama dinosaur", "winged pencil",
            "dancing mug", "smiling cloud", "skateboard cat", "sun umbrella",
            "pizza hat", "bouncing mushroom", "running house", "submarine bird", "lemon car",
            "balloon bridge", "sock tree", "koala astronaut", "banana guitar", "penguin pilot"
    ]
    static let medium: [String] = [
        "neon city", "robot shepherd", "camel in snowy desert", "space train",
          "endless escalator", "crystal tower", "pillow dragon",
          "wind factory", "time suitcase", "bullet watermelon", "ocean in a jar",
          "forest from a pencil"
    ]
    static let hard: [String] = [
        "reverse gravity world", "infinite mirror corridor", "invisible umbrella trail",
           "campfire under water", "walking clock tower"
    ]
    static func random() -> String { (easy + medium + hard).randomElement() ?? "flying fish" }
}

// MARK: - Daily Word Provider
enum DailyWordProvider {
    static func todayWord() -> String {
        let keyWord = "daily_word"
        let keyDate = "daily_word_date"
        let today = Self.todayStamp()
        let ud = UserDefaults.standard

        if let savedDate = ud.string(forKey: keyDate), savedDate == today, let w = ud.string(forKey: keyWord) {
            return w
        }
        let w = WordProvider.random()
        ud.set(today, forKey: keyDate)
        ud.set(w, forKey: keyWord)
        return w
    }

    private static func todayStamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US")
        return f.string(from: Date())
    }
}

#Preview {
    ContentView()
}
