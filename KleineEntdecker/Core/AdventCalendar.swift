import Foundation

/// Huhus Adventskalender: 24 Türchen, pro Tag eines – mit Bild und einer kleinen Mitmach-Idee.
struct AdventDoor: Equatable {
    let number: Int
    let emoji: String
    /// Was hinter der Tür ist, z. B. „Ein Rentier!“.
    let title: String
    /// Kleine Idee zum Mitmachen – meist ohne Bildschirm.
    let idea: String

    var spoken: String { "\(title) \(idea)" }
}

enum AdventCalendar {
    static let doors: [AdventDoor] = [
        .init(number: 1, emoji: "❄️", title: "Eine Schneeflocke!", idea: "Tanz wie eine Schneeflocke durchs Zimmer!"),
        .init(number: 2, emoji: "🦌", title: "Ein Rentier!", idea: "Hüpf dreimal wie ein Rentier!"),
        .init(number: 3, emoji: "🍪", title: "Ein Plätzchen!", idea: "Welche Plätzchen magst du am liebsten?"),
        .init(number: 4, emoji: "🌲", title: "Ein Tannenbaum!", idea: "Streck dich so groß wie ein Tannenbaum!"),
        .init(number: 5, emoji: "🥾", title: "Ein Stiefel!", idea: "Heute Abend stellen viele Kinder ihre Stiefel raus."),
        .init(number: 6, emoji: "🎅", title: "Heute ist Nikolaus!", idea: "Sing ein Lied für den Nikolaus!"),
        .init(number: 7, emoji: "⛄", title: "Ein Schneemann!", idea: "Mal mit dem Finger einen Schneemann in die Luft!"),
        .init(number: 8, emoji: "🔔", title: "Eine Glocke!", idea: "Kling, kling – mach ein Glöckchen-Geräusch!"),
        .init(number: 9, emoji: "🧤", title: "Handschuhe!", idea: "Wie viele Finger hat ein Handschuh?"),
        .init(number: 10, emoji: "🐧", title: "Ein Pinguin!", idea: "Watschel wie ein Pinguin!"),
        .init(number: 11, emoji: "🌟", title: "Ein Stern!", idea: "Mach dich groß wie ein Stern: Arme und Beine weit auseinander!"),
        .init(number: 12, emoji: "🛷", title: "Ein Schlitten!", idea: "Setz dich hin und fahr Schlitten – wuuusch!"),
        .init(number: 13, emoji: "🕯️", title: "Eine Kerze!", idea: "Kerzen zündet man nur mit Erwachsenen an."),
        .init(number: 14, emoji: "🎁", title: "Ein Geschenk!", idea: "Was könntest du jemandem schenken? Ein Bild oder eine Umarmung!"),
        .init(number: 15, emoji: "🍎", title: "Ein Apfel!", idea: "Im Winter gibt es Bratäpfel mit Zimt."),
        .init(number: 16, emoji: "🦉", title: "Huhu!", idea: "Wem möchtest du heute Danke sagen?"),
        .init(number: 17, emoji: "🧣", title: "Ein Schal!", idea: "Zieh dich warm an, wenn du rausgehst!"),
        .init(number: 18, emoji: "🐿️", title: "Ein Eichhörnchen!", idea: "Das Eichhörnchen schläft im Winter viel in seinem Nest."),
        .init(number: 19, emoji: "🎶", title: "Musik!", idea: "Sing dein liebstes Winterlied!"),
        .init(number: 20, emoji: "🌙", title: "Der Mond!", idea: "Schau heute Abend mit deiner Familie zum Himmel!"),
        .init(number: 21, emoji: "☀️", title: "Die Sonne!", idea: "Heute ist der kürzeste Tag des Jahres! Danach werden die Tage wieder länger."),
        .init(number: 22, emoji: "🍫", title: "Schokolade!", idea: "Teilen macht Freude!"),
        .init(number: 23, emoji: "🧸", title: "Ein Teddy!", idea: "Kuschel heute mit deinem Lieblingskuscheltier!"),
        .init(number: 24, emoji: "🎄", title: "Heute ist Heiligabend!", idea: "Huhu wünscht dir frohe Weihnachten!"),
    ]

    /// Feste, gemischte Anordnung der Türchen – wie bei einem echten Kalender.
    static let layout: [Int] = [7, 19, 2, 14, 22, 10, 5, 17, 1, 12, 24, 8, 15, 3, 20, 11, 6, 23, 9, 18, 13, 4, 16, 21]

    static let intro = "Huhus Adventskalender!"
    static let lockedDoor = "Diese Tür ist noch zu."
    static let alreadyOpenedToday = "Dein Türchen für heute ist schon offen. Morgen geht das nächste auf!"

    static func findDoor(_ day: Int) -> String {
        "Finde die Tür mit der Zahl \(NumberBuilder.word(day))!"
    }

    /// „Noch einmal schlafen!“, „Noch dreimal schlafen!“ …
    static func sleepsUntil(_ nights: Int) -> String {
        let times = nights == 1 ? "einmal" : "\(NumberBuilder.word(nights))mal"
        return "Noch \(times) schlafen!"
    }

    // MARK: - Datum

    /// Für Screenshots und Tests: fester Kalendertag.
    static var dayOverride: Int?

    /// Welcher Dezembertag heute ist (1–26), sonst `nil` – dann ist der Kalender nicht zu sehen.
    /// Bis zum 26. bleibt er sichtbar, damit verpasste Türchen nachgeholt werden können.
    static func day(at date: Date = Date(), calendar: Calendar = .current) -> Int? {
        if let dayOverride { return dayOverride }
        guard calendar.component(.month, from: date) == 12 else { return nil }
        let day = calendar.component(.day, from: date)
        return day <= 26 ? day : nil
    }

    // MARK: - Geöffnete Türen (nur auf dem Gerät, je Jahr)

    private static func storageKey(year: Int) -> String { "adventDoorsOpened-\(year)" }

    static func openedDoors(year: Int = Calendar.current.component(.year, from: Date())) -> Set<Int> {
        Set(UserDefaults.standard.array(forKey: storageKey(year: year)) as? [Int] ?? [])
    }

    static func markOpened(_ number: Int, year: Int = Calendar.current.component(.year, from: Date())) {
        var opened = openedDoors(year: year)
        opened.insert(number)
        UserDefaults.standard.set(opened.sorted(), forKey: storageKey(year: year))
    }

    static func resetOpenedDoors(year: Int = Calendar.current.component(.year, from: Date())) {
        UserDefaults.standard.removeObject(forKey: storageKey(year: year))
    }

    /// Alle Sätze, die der Kalender sprechen kann (für Tests und Vertonung).
    static var allTexts: [String] {
        [intro, lockedDoor, alreadyOpenedToday]
            + doors.map(\.spoken)
            + (1...24).map(findDoor)
            + (1...23).map(sleepsUntil)
    }
}
