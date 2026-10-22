# Veröffentlichung im Apple App Store – Schritt für Schritt

Die Veröffentlichung muss über **Ihren eigenen Apple-Developer-Account** erfolgen – Apple verlangt, dass der
Anbieter (Sie) Verträge, Identität und Steuerangaben selbst bestätigt.

## 1. Apple Developer Program (einmalig)

1. Unter <https://developer.apple.com/programs/enroll/> mit Ihrer Apple-ID anmelden (99 € pro Jahr).
   Als Privatperson erscheint Ihr Name als Anbieter im App Store.
2. Nach der Freischaltung in App Store Connect unter *Verträge* den Vertrag für kostenlose Apps akzeptieren.
3. Die **Team-ID** notieren: developer.apple.com → *Membership details*.

## 2. Bundle-ID anpassen

In `project.yml` ist `de.podolskis.kleineentdecker` eingetragen. Falls Sie eine andere ID möchten, ändern Sie
`PRODUCT_BUNDLE_IDENTIFIER` (und `bundleIdPrefix`). Die ID ist nach der ersten Veröffentlichung fest.

## 3. App in App Store Connect anlegen

<https://appstoreconnect.apple.com> → *Apps* → **+** → *Neue App*

| Feld | Wert |
|---|---|
| Plattform | iOS |
| Name | Kleine Entdecker - Lernspiele (in App Store Connect festgelegt) |
| Primärsprache | Deutsch |
| Bundle-ID | de.podolskis.kleineentdecker |
| SKU | kleineentdecker-001 |

## 4. Ohne Mac: alles über GitHub Actions (empfohlen)

### 4a. API-Schlüssel anlegen (einmalig)
1. App Store Connect → *Benutzer und Zugriff* → *Integrationen* → *App Store Connect API* →
   *Team-Schlüssel* → **+**. Name z. B. „GitHub“, Zugriff **Admin**.
2. Die `.p8`-Datei herunterladen (geht nur einmal!), **Key-ID** und **Issuer-ID** notieren.
3. Die Team-ID steht unter developer.apple.com → *Account* → *Membership details*.

### 4b. Secrets in GitHub hinterlegen
GitHub-Repository → *Settings* → *Secrets and variables* → *Actions* → *New repository secret*:

| Name | Inhalt |
|---|---|
| `APPLE_TEAM_ID` | Team-ID (10 Zeichen) |
| `ASC_KEY_ID` | Key-ID des API-Schlüssels |
| `ASC_ISSUER_ID` | Issuer-ID (lange ID mit Bindestrichen) |
| `ASC_KEY_P8` | kompletter Inhalt der .p8-Datei (mit Editor öffnen, alles kopieren) |

Diese Daten **niemals in den Chat oder in Dateien im Repository** kopieren – das Repository ist öffentlich.

### 4c. Datenschutzseite online stellen
GitHub-Repository → *Settings* → *Pages* → *Source: Deploy from a branch* → Branch **main**, Ordner **/docs** → *Save*.
Danach erreichbar unter <https://nggpfnnzhh-debug.github.io/huhu-eule/privacy.html>.

### 4d. Workflow starten
GitHub → *Actions* → **App Store – Hochladen & Einreichen** → *Run workflow*.
- Ohne Haken bei „einreichen“: App, Texte und Screenshots werden hochgeladen; Sie prüfen alles in App Store Connect.
- Mit Haken: zusätzlich wird die App direkt zur Prüfung eingereicht (erst, wenn Schritt 5 erledigt ist).

**Alternative mit Mac:** `xcodegen generate`, Projekt in Xcode öffnen, Team wählen, *Product → Archive* → *Distribute App*.

## 5. Was nur im Browser geht (App Store Connect)

Diese Angaben lassen sich nicht automatisch setzen – einmalig in App Store Connect bei der App ausfüllen:
- **Altersfreigabe**: Fragebogen, alles „Nein/Keine“; bei „Für Kinder gemacht“ → **5 Jahre und jünger**
- **App-Datenschutz**: „Nein, wir erheben keine Daten“ → *Veröffentlichen*
- **Preise und Verfügbarkeit**: Preis **0 € (kostenlos)**, alle Länder oder nur Deutschland/Österreich/Schweiz
- **App-Prüfung → Kontaktinformationen**: Name, Telefon, E-Mail (nur für Apple sichtbar)
- **Kategorie**: Bildung (wird automatisch gesetzt)

## 6. Referenz: Store-Eintrag (wird automatisch hochgeladen)

### Kategorie & Altersfreigabe
- **Primäre Kategorie:** Bildung · **Sekundäre Kategorie:** Kinder (Kids-Kategorie) → Altersgruppe **„5 und jünger“**
- **Altersfreigabe-Fragebogen:** alle Fragen mit „Keine“ beantworten → Ergebnis 4+
- **Preis:** Kostenlos

### App-Datenschutz
- *Datenerhebung:* **„Nein, wir erheben keine Daten von dieser App“**
- *Datenschutzrichtlinie (URL):* Pflicht für Kinder-Apps. Die fertige Seite liegt unter `docs/privacy.html`.
  Hosten Sie sie z. B. über GitHub Pages (*Settings → Pages → Branch: main, Ordner /docs*) – die URL lautet dann
  `https://<github-name>.github.io/<repo>/privacy.html`. Bitte vorher Namen und Kontakt-E-Mail eintragen.

### Texte (Deutsch)

**Untertitel** (max. 30 Zeichen):
```
Zählen, Farben & Buchstaben
```

**Werbetext** (max. 170 Zeichen):
```
Spielerisch lernen ohne Werbung: Zählen, Farben, Formen, Anlaute, Muster und Memory – mit Sprachausgabe für Kinder, die noch nicht lesen können.
```

**Beschreibung:**
```
Kleine Entdecker ist eine liebevoll gestaltete Lern-App für Kinder im Vorschulalter (ca. 4–6 Jahre).

Alle Aufgaben werden vorgelesen – Ihr Kind kann ganz allein spielen, auch wenn es noch nicht lesen kann.
Fehler werden nie bestraft: Die App erklärt freundlich, was richtig gewesen wäre, und ermutigt zum
Weiterprobieren. Nach jeder Runde gibt es einen Stern.

SECHS LERNSPIELE
• Zählen – Mengen bis 5 oder 10 erfassen. Durch Antippen der Bilder zählt Ihr Kind laut mit.
• Farben – Grund- und Mischfarben erkennen und benennen.
• Formen – Kreis, Dreieck, Quadrat & Co. unterscheiden.
• Buchstaben – Anlaute hören: „Was fängt mit M an?“ – eine wichtige Grundlage fürs Lesenlernen.
• Muster – Reihen fortsetzen und logisch denken.
• Memory – Gedächtnis und Konzentration trainieren.

FÜR ELTERN
• Elternbereich mit Schutzabfrage
• Zahlenraum (bis 5 oder bis 10) einstellbar
• Pausen-Erinnerung nach 10 bis 30 Minuten
• Übersicht, was jedes Spiel fördert

SICHER & DATENSPARSAM
• Keine Werbung
• Keine In-App-Käufe
• Keine Links nach außen
• Keine Datenerhebung, kein Tracking
• Funktioniert komplett offline
```

**Schlüsselwörter** (max. 100 Zeichen, durch Komma getrennt):
```
lernen,kinder,vorschule,kindergarten,zählen,zahlen,farben,formen,buchstaben,abc,memory,lernspiel
```

**Support-URL:** z. B. die GitHub-Seite des Projekts oder eine einfache Kontaktseite.

### Screenshots (Pflicht)
- **iPhone 6,9"** (1320 × 2868 px) – z. B. Simulator „iPhone 16 Pro Max“
- **iPad 13"** (2064 × 2752 px) – z. B. Simulator „iPad Pro 13-inch (M4)“

Im Simulator mit **⌘ S** aufnehmen. Empfohlen: Startbildschirm, Zählen, Buchstaben, Memory, Belohnungsstern.
Es reichen 3–5 Bilder pro Gerät.

### Hinweise für die App-Prüfung (App Review Information)
```
Lern-App für Kinder ab 4 Jahren. Keine Anmeldung nötig.
Der Elternbereich (Schloss-Symbol oben rechts) ist durch eine Rechenaufgabe geschützt (z. B. „7 × 8“).
Die App nutzt keine Netzwerkverbindungen, keine Werbung, keine Analyse-Dienste und keine In-App-Käufe.
```

## 7. Einreichen

Build unter *Build* auswählen → *Zur Prüfung hinzufügen* → *Zur Prüfung einreichen*.
Die Prüfung dauert meist 1–3 Tage. Kinder-Apps werden besonders genau geprüft (Richtlinien 1.3 und 5.1.4) –
diese App erfüllt sie bereits: keine Drittanbieter-SDKs, keine Werbung, keine externen Links, Elternschranke.

## Checkliste

- [ ] Apple Developer Program aktiv, Vertrag für kostenlose Apps akzeptiert
- [ ] App in App Store Connect angelegt
- [ ] Build hochgeladen und per TestFlight auf dem eigenen Gerät getestet
- [ ] Datenschutzerklärung mit Name/E-Mail ergänzt und online gestellt
- [ ] Screenshots iPhone 6,9" und iPad 13"
- [ ] Texte, Kategorie (Bildung + Kinder „5 und jünger“), Altersfreigabe, Datenschutz-Angaben
- [ ] Zur Prüfung eingereicht
