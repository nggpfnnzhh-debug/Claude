# Lernlabor

Lern-App für Erwachsene (iPhone & iPad, Deutsch, ab iOS 17): Finde mit kleinen Selbstversuchen heraus,
wie du wirklich am besten lernst.

## Inhalt der ersten Version (0.1)

- **Persönlichkeit:** kurzer Big-Five-Fragebogen (Mini-IPIP, 20 Aussagen), Ergebnis als fünf Tiere mit
  Prozentrang gegenüber Vergleichswerten und Lerntipps:
  🦫 Biber (Gewissenhaftigkeit), Erdmännchen (Geselligkeit), 🐙 Krake (Offenheit),
  🐘 Elefant (Verträglichkeit), 🐢 Schildkröte (Gelassenheit)
- **Selbstversuch „Lesen oder Abfragen?“:** 16 Suaheli-Wörter, zufällig je zur Hälfte nochmal gelesen oder
  abgefragt, Test nach 2 Tagen (mit Erinnerung) oder als Schnell-Demo
- **Mythen-Check:** 8 Lern-Mythen mit Auflösung
- **Lernprofil:** Persönlichkeit und Messergebnisse
- **Vollversion:** einmaliger Kauf (`de.podolskis.lernlabor.vollversion`), Wiederherstellen, Code einlösen
- **Datenschutz:** alles bleibt auf dem Gerät, kein Konto, kein Tracking

## Vor einer Veröffentlichung offen

- Deutsche Vergleichswerte für den Fragebogen (bisher vorläufige US-Werte, `PersonalityTest.norms`)
- Geprüfte deutsche Übersetzung der 20 Aussagen
- Inhalte der Vollversion (weitere Selbstversuche)
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
Vorschau-Screenshots in den Branch `lernlabor-vorschau-<branch>`.
