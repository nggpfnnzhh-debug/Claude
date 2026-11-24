import Foundation

/// „Huhus Jahr“: Jahreszeit und Feste nach dem Datum auf dem Gerät – ganz ohne Internet.
/// Eltern können das im Elternbereich ausschalten.
struct Seasonal: Equatable {
    enum Season: String, CaseIterable {
        case spring, summer, autumn, winter
    }

    enum Festival: String, CaseIterable {
        case halloween, advent, nikolaus, christmas, newYear
    }

    var season: Season
    /// Ein Fest, das gerade bevorsteht oder heute ist.
    var festival: Festival?
    /// `true` am Festtag selbst, `false` in den Tagen davor (Silvester: `false`, Neujahr: `true`).
    var isFestivalDay = false
    /// Brennende Kerzen am Adventskranz (0 außerhalb der Adventszeit).
    var adventCandles = 0

    // MARK: - Datum

    static func at(_ date: Date, calendar: Calendar = .current) -> Seasonal {
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        // Meteorologische Jahreszeiten – für Kinder am leichtesten nachvollziehbar.
        let season: Season
        switch month {
        case 3...5: season = .spring
        case 6...8: season = .summer
        case 9...11: season = .autumn
        default: season = .winter
        }

        var result = Seasonal(season: season)
        result.adventCandles = adventCandles(at: date, calendar: calendar)
        switch (month, day) {
        case (10, 24...31):
            result.festival = .halloween
            result.isFestivalDay = day == 31
        case (12, 5...6):
            result.festival = .nikolaus
            result.isFestivalDay = day == 6
        case (12, 24...26):
            result.festival = .christmas
            result.isFestivalDay = true
        case (12, 31), (1, 1):
            result.festival = .newYear
            result.isFestivalDay = month == 1
        default:
            if result.adventCandles > 0 { result.festival = .advent }
        }
        return result
    }

    /// Der 4. Advent ist der letzte Sonntag vor dem 25. Dezember; der 1. Advent drei Wochen davor.
    /// Gibt die Zahl der brennenden Kerzen zurück (1–4), außerhalb der Adventszeit 0.
    static func adventCandles(at date: Date, calendar: Calendar = .current) -> Int {
        let year = calendar.component(.year, from: date)
        guard let christmasEve = calendar.date(from: DateComponents(year: year, month: 12, day: 24)) else { return 0 }
        let weekday = calendar.component(.weekday, from: christmasEve) // 1 = Sonntag
        guard let fourthAdvent = calendar.date(byAdding: .day, value: -(weekday - 1), to: christmasEve),
              let firstAdvent = calendar.date(byAdding: .day, value: -21, to: fourthAdvent) else { return 0 }
        let today = calendar.startOfDay(for: date)
        guard today >= firstAdvent, today < christmasEve else { return 0 }
        let days = calendar.dateComponents([.day], from: firstAdvent, to: today).day ?? 0
        return min(4, days / 7 + 1)
    }

    /// Für Screenshots und Tests: feste Jahreszeit statt Datum.
    static var override: Seasonal?

    /// Was die App gerade zeigt – `nil`, wenn Eltern „Feste & Jahreszeiten“ ausgeschaltet haben.
    static var active: Seasonal? {
        if let override { return override }
        let enabled = UserDefaults.standard.object(forKey: SettingsKey.seasonalThemes) as? Bool ?? true
        return enabled ? at(Date()) : nil
    }

    /// Alle Varianten, die vorkommen können (für Tests).
    static var allVariants: [Seasonal] {
        var variants = Season.allCases.map { Seasonal(season: $0) }
        variants.append(Seasonal(season: .autumn, festival: .halloween, isFestivalDay: false))
        variants.append(Seasonal(season: .autumn, festival: .halloween, isFestivalDay: true))
        for candles in 1...4 {
            variants.append(Seasonal(season: .winter, festival: .advent, adventCandles: candles))
        }
        variants.append(Seasonal(season: .winter, festival: .nikolaus, isFestivalDay: false, adventCandles: 1))
        variants.append(Seasonal(season: .winter, festival: .nikolaus, isFestivalDay: true, adventCandles: 1))
        variants.append(Seasonal(season: .winter, festival: .christmas, isFestivalDay: true))
        variants.append(Seasonal(season: .winter, festival: .newYear, isFestivalDay: false))
        variants.append(Seasonal(season: .winter, festival: .newYear, isFestivalDay: true))
        return variants
    }

    // MARK: - Inhalte

    /// Ansage nach der Begrüßung, z. B. „Bald ist Halloween!“.
    var announcement: String? {
        switch festival {
        case .halloween: return isFestivalDay ? "Heute ist Halloween!" : "Bald ist Halloween!"
        case .advent: return "Es ist Adventszeit! \(Self.candlesText(adventCandles))"
        case .nikolaus: return isFestivalDay ? "Heute ist Nikolaus!" : "Morgen ist Nikolaus!"
        case .christmas: return "Frohe Weihnachten!"
        case .newYear: return isFestivalDay ? "Frohes neues Jahr!" : "Heute ist Silvester!"
        case nil: return nil
        }
    }

    static func candlesText(_ candles: Int) -> String {
        candles == 1
            ? "Am Adventskranz brennt schon eine Kerze."
            : "Am Adventskranz brennen schon \(Phrases.numberWords[candles]) Kerzen."
    }

    private static let christmasCountItems: [TaskFactory.CountItem] = [
        .init(emoji: "🎁", plural: "Geschenke"),
        .init(emoji: "🕯️", plural: "Kerzen"),
        .init(emoji: "🍪", plural: "Kekse"),
        .init(emoji: "🎄", plural: "Tannenbäume"),
    ]

    private static let christmasMemory: [(emoji: String, name: String)] = [
        ("🎄", "Tannenbaum"), ("🎁", "Geschenk"), ("🕯️", "Kerze"), ("🍪", "Keks"),
    ]

    /// Zusätzliche Dinge zum Zählen.
    var countItems: [TaskFactory.CountItem] {
        switch festival {
        case .halloween:
            return [
                .init(emoji: "🎃", plural: "Kürbisse"),
                .init(emoji: "🦇", plural: "Fledermäuse"),
                .init(emoji: "👻", plural: "Gespenster"),
                .init(emoji: "🍬", plural: "Bonbons"),
            ]
        case .advent, .nikolaus, .christmas:
            return Self.christmasCountItems
        case .newYear, nil:
            break
        }
        switch season {
        case .autumn:
            return [
                .init(emoji: "🍂", plural: "Blätter"),
                .init(emoji: "🌰", plural: "Kastanien"),
                .init(emoji: "🍄", plural: "Pilze"),
                .init(emoji: "🦔", plural: "Igel"),
            ]
        case .winter:
            return [
                .init(emoji: "⛄", plural: "Schneemänner"),
                .init(emoji: "❄️", plural: "Schneeflocken"),
                .init(emoji: "🧤", plural: "Handschuhe"),
                .init(emoji: "🛷", plural: "Schlitten"),
            ]
        case .spring, .summer:
            return []
        }
    }

    /// Zusätzliche Memory-Motive.
    var memoryCards: [(emoji: String, name: String)] {
        switch festival {
        case .halloween:
            return [("🎃", "Kürbis"), ("🦇", "Fledermaus"), ("👻", "Gespenst"), ("🍬", "Bonbon")]
        case .advent, .nikolaus, .christmas:
            return Self.christmasMemory
        case .newYear, nil:
            break
        }
        switch season {
        case .autumn:
            return [("🦔", "Igel"), ("🐿️", "Eichhörnchen"), ("🍄", "Pilz"), ("🌰", "Kastanie")]
        case .winter:
            return [("⛄", "Schneemann"), ("🧤", "Handschuh"), ("🛷", "Schlitten"), ("🐧", "Pinguin")]
        case .spring, .summer:
            return []
        }
    }

    /// Was auf dem Startbildschirm sanft herabschwebt.
    var decorations: [String] {
        switch festival {
        case .halloween: return ["🦇", "🍂", "🎃"]
        case .advent: return ["❄️", "⭐️"]
        case .nikolaus: return ["❄️", "🍪", "⭐️"]
        case .christmas: return ["❄️", "⭐️", "🎄"]
        case .newYear: return ["✨", "🎆"]
        case nil: break
        }
        switch season {
        case .spring: return ["🌸", "🌼"]
        case .summer: return ["🦋", "🌼"]
        case .autumn: return ["🍂", "🍁"]
        case .winter: return ["❄️"]
        }
    }

    /// Kleines Zeichen an Huhu, z. B. ein Kürbis zu Halloween.
    var owlAccessory: String? {
        switch festival {
        case .halloween: return "🎃"
        case .nikolaus: return "🥾"
        case .christmas: return "🎁"
        case .newYear: return "🎉"
        case .advent, nil: return season == .winter || festival == .advent ? "🧣" : nil
        }
    }
}
