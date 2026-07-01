//
//  Models.swift
//  Doodle60
//
//  Word prompts, difficulty tagging, and on-disk gallery storage.
//

import SwiftUI
import UIKit

// MARK: - Difficulty
enum Difficulty: String {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
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

    static func difficulty(of word: String) -> Difficulty {
        if easy.contains(word) { return .easy }
        if medium.contains(word) { return .medium }
        return .hard
    }
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

// MARK: - Stats (streak & totals)
enum StatsStore {
    private static let totalKey = "stats_total_drawings"
    private static let streakKey = "stats_streak"
    private static let lastDayKey = "stats_last_draw_day"

    static var totalDrawings: Int {
        UserDefaults.standard.integer(forKey: totalKey)
    }

    static var streak: Int {
        // A streak is only alive if the last drawing was today or yesterday.
        guard let last = lastDrawDay() else { return 0 }
        let cal = Calendar.current
        if cal.isDateInToday(last) || cal.isDateInYesterday(last) {
            return UserDefaults.standard.integer(forKey: streakKey)
        }
        return 0
    }

    static func recordDrawing() {
        let ud = UserDefaults.standard
        ud.set(totalDrawings + 1, forKey: totalKey)

        let cal = Calendar.current
        let last = lastDrawDay()
        if let last, cal.isDateInToday(last) {
            // Already counted today.
        } else if let last, cal.isDateInYesterday(last) {
            ud.set(ud.integer(forKey: streakKey) + 1, forKey: streakKey)
        } else {
            ud.set(1, forKey: streakKey)
        }
        ud.set(dayStamp(Date()), forKey: lastDayKey)
    }

    private static func lastDrawDay() -> Date? {
        guard let stamp = UserDefaults.standard.string(forKey: lastDayKey) else { return nil }
        return dayFormatter.date(from: stamp)
    }

    private static func dayStamp(_ date: Date) -> String {
        dayFormatter.string(from: date)
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}

// MARK: - Gallery storage
struct GalleryItem: Identifiable {
    let id = UUID()
    let url: URL
    let prompt: String
    let date: Date
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

    @discardableResult
    static func save(image: UIImage, prompt: String) -> URL? {
        ensureFolder()
        // Timestamp intentionally contains no "_" so the filename can be split
        // into "<timestamp>-<uniquer>" / "<slug>" on the first underscore.
        let name = "\(timestamp())-\(shortID())_\(slug(prompt)).png"
        let url = folderURL.appendingPathComponent(name)
        guard let data = image.pngData() else { return nil }
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }

    static func loadAll() -> [GalleryItem] {
        ensureFolder()
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.contentModificationDateKey]
        )) ?? []
        let pngs = urls.filter { $0.pathExtension.lowercased() == "png" }
        return pngs
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
            .map { url in
                let base = url.deletingPathExtension().lastPathComponent
                let parts = base.split(separator: "_", maxSplits: 1).map(String.init)
                let prompt = parts.count > 1 ? parts[1].replacingOccurrences(of: "-", with: " ") : ""
                let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date()
                return GalleryItem(url: url, prompt: prompt, date: date)
            }
    }

    static func delete(url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    static func deleteAll() {
        let items = loadAll()
        for item in items { delete(url: item.url) }
    }

    private static func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMddHHmmss"
        return f.string(from: Date())
    }

    private static func shortID() -> String {
        String(UUID().uuidString.prefix(4))
    }

    private static func slug(_ s: String) -> String {
        let ascii = s.folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return String(ascii.unicodeScalars.filter { allowed.contains($0) })
    }
}
