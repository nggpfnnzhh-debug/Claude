import Foundation

struct Myth: Identifiable {
    enum Verdict {
        case wrong, partly, right

        var label: String {
            switch self {
            case .wrong: return "FALSCH"
            case .partly: return "TEILWEISE"
            case .right: return "STIMMT"
            }
        }
    }

    let id: Int
    let claim: String
    let verdict: Verdict
    let explanation: String

    static let all: [Myth] = [
        Myth(id: 0, claim: "Jeder Mensch hat einen Lerntyp: visuell, auditiv oder haptisch.", verdict: .wrong,
             explanation: "Menschen haben Vorlieben, aber wer nach seinem „Typ“ lernt, lernt in Studien nicht besser. Was wirkt, hängt vor allem vom Stoff ab: Aussprache lernt jeder besser über das Ohr, Landkarten jeder besser über das Auge. Am besten wirkt die Kombination."),
        Myth(id: 1, claim: "Nochmal lesen ist eine gute Lernmethode.", verdict: .wrong,
             explanation: "Es fühlt sich gut an, weil der Text vertraut wirkt. Sich selbst abfragen bringt aber deutlich mehr, vor allem nach ein paar Tagen. Probier es im Selbstversuch aus."),
        Myth(id: 2, claim: "Wir nutzen nur 10 % unseres Gehirns.", verdict: .wrong,
             explanation: "Hirnscans zeigen: Über den Tag sind praktisch alle Bereiche aktiv. Ein „ungenutztes Reservegehirn“ gibt es nicht."),
        Myth(id: 3, claim: "Mozart-Musik macht schlauer.", verdict: .wrong,
             explanation: "Der berühmte Effekt war winzig, kurz und ließ sich kaum wiederholen. Musik kann die Stimmung heben, schlauer macht sie nicht."),
        Myth(id: 4, claim: "Verteilt lernen schlägt Pauken am Stück.", verdict: .right,
             explanation: "Dreimal 20 Minuten an verschiedenen Tagen bringen mehr als eine Stunde am Stück. Das ist einer der am besten belegten Befunde der Lernforschung."),
        Myth(id: 5, claim: "Mit Multitasking schafft man mehr.", verdict: .wrong,
             explanation: "Das Gehirn springt zwischen Aufgaben hin und her. Das kostet Zeit und erzeugt Fehler. Handy weg beim Lernen hilft messbar."),
        Myth(id: 6, claim: "Es gibt Morgen- und Abendmenschen.", verdict: .right,
             explanation: "Der Schlaftyp (Lerche oder Eule) ist biologisch gut belegt und verändert sich mit dem Alter. Wann du lernst, kann also einen Unterschied machen."),
        Myth(id: 7, claim: "Die Persönlichkeit bestimmt, welche Lernmethode wirkt.", verdict: .partly,
             explanation: "Persönlichkeit sagt viel darüber, wie gut du dranbleibst. Dass sie die beste Methode festlegt, ist nicht belegt. Darum testet das Lernlabor, statt zu raten."),
    ]
}
