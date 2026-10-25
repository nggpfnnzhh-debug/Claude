import Foundation

/// „Huhus Jahr“: Jahreszeit und Feste nach dem Datum auf dem Gerät – ganz ohne Internet.
/// Eltern können das im Elternbereich ausschalten.
struct Seasonal: Equatable {
    enum Season: String, CaseIterable {
        case spring, summer, autumn, winter
    }

    enum Festival: String, CaseIterable {
        case halloween
    }

    var season: Season
    /// Ein Fest, das gerade bevorsteht oder heute ist.
    var festival: Festival?
    /// `true` am Festtag selbst, `false` in den Tagen davor.
    var isFestivalDay = false

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
        if month == 10, day >= 24 {
            result.festival = .halloween
            result.isFestivalDay = day == 31
        }
        return result
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
        return variants
    }

    // MARK: - Inhalte

    /// Ansage nach der Begrüßung, z. B. „Bald ist Halloween!“.
    var announcement: String? {
        switch festival {
        case .halloween: return isFestivalDay ? "Heute ist Halloween!" : "Bald ist Halloween!"
        case nil: return nil
        }
    }

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
        case nil:
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
        case .spring, .summer, .winter:
            return []
        }
    }

    /// Zusätzliche Memory-Motive.
    var memoryCards: [(emoji: String, name: String)] {
        switch festival {
        case .halloween:
            return [("🎃", "Kürbis"), ("🦇", "Fledermaus"), ("👻", "Gespenst"), ("🍬", "Bonbon")]
        case nil:
            break
        }
        switch season {
        case .autumn:
            return [("🦔", "Igel"), ("🐿️", "Eichhörnchen"), ("🍄", "Pilz"), ("🌰", "Kastanie")]
        case .spring, .summer, .winter:
            return []
        }
    }

    /// Was auf dem Startbildschirm sanft herabschwebt.
    var decorations: [String] {
        if festival == .halloween { return ["🦇", "🍂", "🎃"] }
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
        case nil: return season == .winter ? "🧣" : nil
        }
    }
}
