# Lernlabor auf dem eigenen iPhone testen (TestFlight)

Die Secrets für GitHub (`APPLE_TEAM_ID`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`) sind von Huhu Eule
schon eingerichtet und werden wiederverwendet. Es fehlen nur drei einmalige Schritte bei Apple.

## 1. Bundle-ID registrieren (2 Minuten)

<https://developer.apple.com/account/resources/identifiers/list> → **+** → *App IDs* → *App*

| Feld | Wert |
|---|---|
| Description | Lernlabor |
| Bundle ID | *Explicit*: `de.podolskis.lernlabor` |
| Capabilities | nichts zusätzlich nötig (In-App Purchase ist immer aktiv) |

## 2. App in App Store Connect anlegen (3 Minuten)

<https://appstoreconnect.apple.com> → *Apps* → **+** → *Neue App*

| Feld | Wert |
|---|---|
| Plattform | iOS |
| Name | Lernlabor (muss im App Store frei sein, sonst z. B. „Lernlabor – Wie lerne ich?“) |
| Primärsprache | Deutsch |
| Bundle-ID | de.podolskis.lernlabor |
| SKU | lernlabor-001 |
| Benutzerzugriff | Uneingeschränkt |

## 3. Hochladen

GitHub → *Actions* → **Lernlabor – Upload zu TestFlight** → *Run workflow* (Branch mit dem Lernlabor wählen).
Der Workflow erscheint dort erst, wenn er im Hauptzweig `main` liegt (GitHub zeigt den Knopf „Run workflow“
nur für Workflows aus dem Hauptzweig).
Nach etwa 15 Minuten erscheint der Build in App Store Connect unter *TestFlight*; Apple prüft ihn danach
noch einige Minuten („Wird verarbeitet“).

## 4. Testen

- **Du selbst und dein Team (interne Tester, bis 100 Personen):** App Store Connect → *TestFlight* →
  *Interne Tests* → Gruppe anlegen → dich hinzufügen. Auf dem iPhone die App **TestFlight** aus dem App Store
  laden, Einladung annehmen, Lernlabor installieren. Keine Prüfung durch Apple nötig.
- **Freunde und Kollegen (externe Tester, bis 10.000):** *Externe Tests* → Gruppe anlegen → E-Mail-Adressen
  eintragen oder einen öffentlichen Link erzeugen. Beim ersten Build prüft Apple kurz (meist 1 Tag).
  Dafür verlangt Apple eine Beschreibung und eine Kontakt-E-Mail für Tester. Eine eigene Adresse für die
  App (keine private) ist hier sinnvoll.

## Vollversion in der Testversion

In TestFlight-Versionen gibt es im Profil den Schalter **„Vollversion simulieren“**. Damit lässt sich alles
testen, ohne dass ein Kauf eingerichtet sein muss.

Echte Testkäufe (kostenlos, mit Sandbox) gehen erst, wenn

1. der **Vertrag für kostenpflichtige Apps** in App Store Connect aktiv ist (Bank- und Steuerdaten,
   Händlerangaben: vorher klären, welche Adresse und Telefonnummer öffentlich erscheinen dürfen), und
2. unter *Monetarisierung* → *In-App-Käufe* das Produkt angelegt ist:
   Typ *Nicht-verbrauchbar*, Produkt-ID `de.podolskis.lernlabor.vollversion`, Preis z. B. 7,99 €.

## Neue Version testen

Einfach den Workflow erneut starten. Die Build-Nummer wird automatisch hochgezählt.
