# Kleine Entdecker 🦉

Eine pädagogische Lern-App für Kinder von etwa 4 bis 6 Jahren (iPhone & iPad, Deutsch).

Alle Anweisungen werden **vorgelesen** – das Kind muss nicht lesen können. Falsche Antworten werden nicht
bestraft, sondern freundlich erklärt („Das ist Blau. Wo ist Rot?“). Nach jeder Runde gibt es einen Stern.

## Spiele

| Spiel | Was wird gelernt? |
|---|---|
| 🐞 **Zählen** | Mengen bis 5 (oder 10) erfassen; durch Antippen der Bilder wird laut mitgezählt |
| 🎨 **Farben** | Grund- und Mischfarben benennen |
| 🔺 **Formen** | Kreis, Quadrat, Dreieck, Rechteck, Oval, Stern, Herz – unabhängig von der Farbe |
| 🔤 **Buchstaben** | Anlaute hören („Was fängt mit M an?“) – Vorläuferfähigkeit fürs Lesen |
| 🧩 **Muster** | Folgen fortsetzen (AB, AAB, ABB, ABC) – logisches Denken |
| 🃏 **Memory** | Konzentration und Gedächtnis, Tiernamen |

## Für Eltern

- **Elternbereich** (oben rechts, gesichert durch eine Rechenaufgabe): Sprachausgabe, Zahlenraum, Pausen-Erinnerung, Fortschritt.
- **Pausen-Erinnerung**: nach 10–30 Minuten erscheint ein freundlicher Pausenbildschirm; Weiterspielen nur über die Elternschranke.
- **Datenschutz**: keine Werbung, keine In-App-Käufe, keine Links, kein Tracking, keine Netzwerkzugriffe. Der Fortschritt wird nur lokal gespeichert.

## Entwicklung

Voraussetzungen: Mac mit Xcode 16 oder neuer, [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
xcodegen generate          # erzeugt KleineEntdecker.xcodeproj aus project.yml
open KleineEntdecker.xcodeproj
```

In Xcode unter *Signing & Capabilities* das eigene Team wählen und auf einem Simulator oder dem eigenen iPad starten.

```
KleineEntdecker/
  App/        App-Einstieg, Pausen-Logik
  Core/       Spiele-Definition, Sprachausgabe, Fortschritt, Einstellungen
  Games/      Aufgaben-Generatoren für die Lernspiele
  Views/      Oberfläche (Start, Quiz, Memory, Belohnung, Elternbereich)
  Resources/  App-Icon, Farben, Privacy Manifest
KleineEntdeckerTests/   Unit-Tests der Aufgaben-Generatoren
```

GitHub Actions baut die App bei jedem Push und führt die Tests im iOS-Simulator aus
(`.github/workflows/ios-build.yml`). Der Upload zu TestFlight läuft über `.github/workflows/testflight.yml`.

**Veröffentlichung im App Store:** siehe [docs/APP_STORE.md](docs/APP_STORE.md).
