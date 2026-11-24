# Lernlabor 🧪

Lern-App für Erwachsene (iPhone & iPad, Deutsch, ab iOS 17).

Mit kleinen Selbstversuchen findet man heraus, welche Lernmethode bei einem selbst wirklich wirkt. Ein kurzer
Persönlichkeitstest zeigt dazu fünf Tiere mit passenden Lerntipps.

## Inhalte

| Bereich | Was passiert? |
|---|---|
| 🦫 **Persönlichkeit** | 20 Aussagen (Big Five, Mini-IPIP), Ergebnis als Biber, Erdmännchen, Krake, Elefant und Schildkröte |
| 🔤 **Lesen oder Abfragen?** | 16 Suaheli-Wörter, je zur Hälfte nochmal gelesen oder abgefragt, Test nach 2 Tagen |
| 🗣️ **Erklären oder Lesen?** *(Vollversion)* | 12 Fakten, je zur Hälfte nochmal gelesen oder laut erklärt, Test mit Auswahlfragen |
| 💡 **Mythen-Check** | 8 verbreitete Lern-Mythen mit Auflösung |
| 📊 **Lernprofil** | Persönlichkeit und Ergebnisse der Selbstversuche |

## Vollversion

- Einmaliger Kauf, kein Abo (Produkt-ID `de.podolskis.lernlabor.vollversion`)
- Käufe wiederherstellen und Codes einlösen im Profil
- In Testversionen (TestFlight, Xcode) gibt es den Schalter **„Vollversion simulieren“**

## Datenschutz

Keine Werbung, kein Konto, kein Tracking. Alle Ergebnisse bleiben auf dem Gerät.

## Entwicklung

Voraussetzungen: Mac mit Xcode 26 oder neuer, [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
cd Lernlabor
xcodegen generate
open Lernlabor.xcodeproj
```

Testkäufe ohne echtes Geld: Beim Start aus Xcode wird `Lernlabor/Resources/Lernlabor.storekit` verwendet.

GitHub Actions baut die App und führt die Tests aus (`lernlabor.yml`); Upload zu TestFlight:
`lernlabor-testflight.yml`. Veröffentlichung: siehe [docs/APP_STORE.md](docs/APP_STORE.md).
