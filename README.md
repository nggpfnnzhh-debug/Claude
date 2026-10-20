# Huhu Eule 🦉

Pädagogische Lern-App für Kinder von etwa 4 bis 6 Jahren (iPhone & iPad, Deutsch).

Huhu, die Eule, spricht alle Anweisungen vor – das Kind muss nicht lesen können. Falsche Antworten werden
nicht bestraft, sondern freundlich erklärt; nach zwei Fehlversuchen hilft Huhu. Für jede geschaffte Runde
leuchtet ein Stern in Huhus Sternenhimmel. Die Schwierigkeit passt sich automatisch an.

## Spiele

| Spiel | Was wird gelernt? |
|---|---|
| 🐞 **Zählen** | Mengen bis 5, 10 oder 20; durch Antippen wird laut mitgezählt |
| 🎨 **Farben** | Grund- und Mischfarben benennen |
| 🔺 **Formen** | Geometrische Grundformen – unabhängig von der Farbe |
| 🔤 **Buchstaben** | Anlaute hören (als Laut gesprochen: „mmm“ statt „Em“) |
| 🧩 **Muster** | Folgen fortsetzen (AB, AAB, ABB, ABC, AABB) |
| 🃏 **Memory** | Konzentration und Gedächtnis |
| ⚖️ **Mehr oder weniger?** *(Vorschule)* | Mengen vergleichen |
| 👏 **Silben klatschen** *(Vorschule)* | Wörter in Silben zerlegen |
| 🕒 **Uhr lesen** *(Vorschule)* | Volle und halbe Stunden |

## Für Eltern

- **Elternbereich** (gesichert durch eine Rechenaufgabe): Name des Kindes, Fördertipps je Spiel, Pausen-Erinnerung, Fortschritt.
- **Fördertipps**: Die App merkt sich nur lokal, wie oft beim ersten Versuch richtig geantwortet wird, und zeigt Spiele mit Übungsbedarf zuerst.
- **Datenschutz**: keine Werbung, keine In-App-Käufe, keine Links, kein Tracking, keine Netzwerkzugriffe.

## Entwicklung

Voraussetzungen: Mac mit Xcode 26 oder neuer, [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
xcodegen generate
open KleineEntdecker.xcodeproj
```

GitHub Actions baut die App und führt die Tests aus (`ios-build.yml`); Upload und Einreichung:
`app-store.yml` bzw. `testflight.yml`. Veröffentlichung: siehe [docs/APP_STORE.md](docs/APP_STORE.md).

## Stimme

Alle gesprochenen Sätze liegen als Audioaufnahmen in `KleineEntdecker/Resources/Voice/`
(Microsoft-Azure-Sprachsynthese, Stimme „Katja“). Neue oder geänderte Sätze in `scripts/voice/generate.py`
eintragen und den Workflow **„Stimme erzeugen“** starten; das Ergebnis liegt im Branch `stimme-azure`.
Der Test `VoiceCoverageTests` prüft, dass jeder gesprochene Satz eine Aufnahme hat.
