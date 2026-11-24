# Lernlabor: TestFlight und App Store – Schritt für Schritt

Die GitHub-Secrets (`APPLE_TEAM_ID`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`) sind von Huhu Eule bereits
eingerichtet und werden wiederverwendet.

## 1. Bundle-ID registrieren (einmalig)

<https://developer.apple.com/account/resources/identifiers/list> → **+** → *App IDs* → *App*

| Feld | Wert |
|---|---|
| Description | Lernlabor |
| Bundle ID | *Explicit*: `de.podolskis.lernlabor` |
| Capabilities | keine zusätzlichen nötig (In-App-Käufe sind immer aktiv) |

## 2. App in App Store Connect anlegen

<https://appstoreconnect.apple.com> → *Apps* → **+** → *Neue App*

| Feld | Wert |
|---|---|
| Plattform | iOS |
| Name | Lernlabor (falls vergeben, z. B. „Lernlabor – Wie lerne ich?“) |
| Primärsprache | Deutsch |
| Bundle-ID | de.podolskis.lernlabor |
| SKU | lernlabor-001 |

## 3. Zu TestFlight hochladen

GitHub → *Actions* → **Lernlabor – Upload zu TestFlight** → *Run workflow*.
Der Workflow erscheint dort erst, wenn er im Hauptzweig `main` liegt.

Nach etwa 15 Minuten ist der Build in App Store Connect unter *TestFlight* sichtbar; Apple verarbeitet ihn danach
noch einige Minuten. Die Build-Nummer wird automatisch hochgezählt.

## 4. Testen

- **Eigene Geräte und Team (interne Tester, bis 100):** *TestFlight* → *Interne Tests* → Gruppe anlegen →
  Personen hinzufügen. Auf dem iPhone die App **TestFlight** installieren und die Einladung annehmen.
  Keine Prüfung durch Apple nötig.
- **Freunde und Kollegen (externe Tester, bis 10.000):** *Externe Tests* → Gruppe anlegen → E-Mail-Adressen
  eintragen oder öffentlichen Link erzeugen. Der erste Build wird von Apple kurz geprüft (meist 1 Tag).

In Testversionen lässt sich die Vollversion im Profil über **„Vollversion simulieren“** freischalten. Echte
Testkäufe sind erst möglich, wenn Schritt 5 erledigt ist.

## 5. Vollversion als In-App-Kauf

1. App Store Connect → *Geschäftlich* → **Vertrag für kostenpflichtige Apps** mit Bank- und Steuerdaten
   abschließen. Achtung: Wer Geld verdient, gilt in der EU als Händler, und Apple zeigt Adresse und Telefonnummer
   öffentlich im App Store. Vorher eine geschäftliche Anschrift und Nummer klären.
2. *Monetarisierung* → *In-App-Käufe* → **+**

| Feld | Wert |
|---|---|
| Typ | Nicht-verbrauchbar |
| Referenzname | Vollversion |
| Produkt-ID | `de.podolskis.lernlabor.vollversion` |
| Preis | 7,99 € |
| Anzeigename / Beschreibung | Vollversion / Alle Selbstversuche und das vollständige Lernprofil |

3. Codes für Freunde und Kollegen: beim In-App-Kauf unter *Angebotscodes* anlegen (bis zu 6 Monate gültig).

## 6. Vor der Veröffentlichung

- Deutsche Vergleichswerte für den Fragebogen eintragen (bisher vorläufige US-Werte in
  `PersonalityTest.norms`)
- Deutsche Übersetzung der 20 Aussagen prüfen lassen
- Weitere Selbstversuche für die Vollversion
- Eigene Illustrationen der Tiere (das Erdmännchen ist bisher eine einfache Zeichnung)
- Datenschutzerklärung erstellen und online stellen
- Store-Texte und Screenshots

## Checkliste

- [ ] Bundle-ID registriert
- [ ] App in App Store Connect angelegt
- [ ] Build über TestFlight auf dem eigenen Gerät getestet
- [ ] Geschäftliche Anschrift und Telefonnummer geklärt
- [ ] Vertrag für kostenpflichtige Apps abgeschlossen, In-App-Kauf angelegt
- [ ] Punkte aus Abschnitt 6 erledigt
- [ ] Zur Prüfung eingereicht
