# Lernlabor

Lern-App für Erwachsene (iPhone & iPad, Deutsch, ab iOS 17): Finde mit kleinen Selbstversuchen heraus,
wie du wirklich am besten lernst.

## Inhalt (Version 0.2)

- **Persönlichkeit:** kurzer Big-Five-Fragebogen (Mini-IPIP, 20 Aussagen), Ergebnis als fünf Tiere mit
  Prozentrang gegenüber Vergleichswerten und Lerntipps:
  🦫 Biber (Gewissenhaftigkeit), Erdmännchen (Geselligkeit), 🐙 Krake (Offenheit),
  🐘 Elefant (Verträglichkeit), 🐢 Schildkröte (Gelassenheit)
- **Selbstversuch 1 „Lesen oder Abfragen?“ (kostenlos):** 16 Suaheli-Wörter, zufällig je zur Hälfte nochmal
  gelesen oder abgefragt, Test nach 2 Tagen (mit Erinnerung) oder als Schnell-Demo
- **Selbstversuch 2 „Erklären oder Lesen?“ (Vollversion):** 12 Fakten, je zur Hälfte nochmal gelesen oder laut
  erklärt, Test mit Auswahlfragen
- **Mythen-Check:** 8 Lern-Mythen mit Auflösung
- **Lernprofil:** Persönlichkeit und Messergebnisse
- **Vollversion:** einmaliger Kauf (`de.podolskis.lernlabor.vollversion`), Wiederherstellen, Code einlösen;
  in Testversionen (TestFlight, Xcode) zusätzlich der Schalter „Vollversion simulieren“
- **Datenschutz:** alles bleibt auf dem Gerät, kein Konto, kein Tracking

## Vor einer Veröffentlichung offen

- Deutsche Vergleichswerte für den Fragebogen (bisher vorläufige US-Werte, `PersonalityTest.norms`)
- Geprüfte deutsche Übersetzung der 20 Aussagen
- Weitere Selbstversuche für die Vollversion
- Eigene Illustrationen der Tiere (das Erdmännchen ist bisher eine einfache Zeichnung)
- Händlerangaben im App Store (Adresse/Telefon) klären

## Entwicklung

Voraussetzungen: Mac mit Xcode 26 oder neuer, [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
cd Lernlabor
xcodegen generate
open Lernlabor.xcodeproj
```

Testkäufe ohne echtes Geld: Beim Start aus Xcode wird `Lernlabor/Resources/Lernlabor.storekit` verwendet.

GitHub Actions (`.github/workflows/lernlabor.yml`) baut die App, führt die Tests aus und legt
Vorschau-Screenshots in den Branch `lernlabor-vorschau-<branch>`. Hochladen zu TestFlight:
`.github/workflows/lernlabor-testflight.yml`, Anleitung in [docs/TESTFLIGHT.md](docs/TESTFLIGHT.md).
