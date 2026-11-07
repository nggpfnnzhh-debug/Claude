import Foundation

/// Bildergeschichten: Bilder in die richtige Reihenfolge bringen. Zu jedem Bild sagt Huhu einen kurzen Satz.
struct StoryStep: Equatable {
    let emoji: String
    let caption: String
}

struct Story: Equatable {
    let steps: [StoryStep]
}

struct StoryTask: Identifiable {
    let id = UUID()
    let story: Story
    /// Die Bilder in der Reihenfolge, in der sie unten liegen (gemischt).
    let shuffledIndices: [Int]
}

enum Stories {
    static let instruction = "Was passiert zuerst? Tippe die Bilder der Reihe nach an!"
    static let later = "Das kommt später!"

    static let short: [Story] = [
        Story(steps: [
            .init(emoji: "❄️", caption: "Es schneit."),
            .init(emoji: "⛄", caption: "Wir bauen einen Schneemann."),
            .init(emoji: "💧", caption: "Der Schneemann ist geschmolzen."),
        ]),
        Story(steps: [
            .init(emoji: "🌱", caption: "Ein Samen keimt."),
            .init(emoji: "🌿", caption: "Die Pflanze wächst."),
            .init(emoji: "🌻", caption: "Eine Sonnenblume blüht."),
        ]),
        Story(steps: [
            .init(emoji: "☁️", caption: "Wolken ziehen auf."),
            .init(emoji: "🌧️", caption: "Es regnet."),
            .init(emoji: "🌈", caption: "Ein Regenbogen!"),
        ]),
        Story(steps: [
            .init(emoji: "🥚", caption: "Wir holen die Zutaten."),
            .init(emoji: "🥣", caption: "Wir rühren den Teig."),
            .init(emoji: "🎂", caption: "Der Kuchen ist fertig!"),
        ]),
        Story(steps: [
            .init(emoji: "🥚", caption: "Ein Ei."),
            .init(emoji: "🐣", caption: "Das Küken schlüpft."),
            .init(emoji: "🐥", caption: "Ein kleines Küken."),
        ]),
    ]

    static let long: [Story] = [
        Story(steps: [
            .init(emoji: "🥚", caption: "Ein Ei."),
            .init(emoji: "🐣", caption: "Das Küken schlüpft."),
            .init(emoji: "🐥", caption: "Ein kleines Küken."),
            .init(emoji: "🐔", caption: "Ein großes Huhn."),
        ]),
        Story(steps: [
            .init(emoji: "🌅", caption: "Die Sonne geht auf."),
            .init(emoji: "☀️", caption: "Mittags scheint die Sonne."),
            .init(emoji: "🌇", caption: "Am Abend geht die Sonne unter."),
            .init(emoji: "🌙", caption: "In der Nacht scheint der Mond."),
        ]),
        Story(steps: [
            .init(emoji: "👶", caption: "Ein Baby."),
            .init(emoji: "🧒", caption: "Ein Kind."),
            .init(emoji: "🧑", caption: "Ein Erwachsener."),
            .init(emoji: "🧓", caption: "Ein alter Mensch."),
        ]),
        Story(steps: [
            .init(emoji: "🌸", caption: "Der Apfelbaum blüht."),
            .init(emoji: "🍏", caption: "Ein kleiner grüner Apfel wächst."),
            .init(emoji: "🍎", caption: "Der Apfel ist reif."),
            .init(emoji: "🥧", caption: "Ein Apfelkuchen!"),
        ]),
    ]

    /// Stufe 0: drei Bilder, Stufe 1: gemischt, Stufe 2: vier Bilder.
    static func tasks(level: Int) -> [StoryTask] {
        let pool: [Story]
        switch level {
        case 0: pool = short
        case 1: pool = short + long
        default: pool = long
        }
        return TaskFactory.varied(pool, count: TaskFactory.tasksPerRound).map { story in
            var order = Array(story.steps.indices)
            // Nie schon richtig sortiert anbieten.
            while order == Array(story.steps.indices) { order.shuffle() }
            return StoryTask(story: story, shuffledIndices: order)
        }
    }

    static var allTexts: [String] {
        [instruction, later] + (short + long).flatMap { $0.steps.map(\.caption) }
    }
}
