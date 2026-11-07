# Changelog

Numerazione: si parte da 0.0.5 e ogni modifica aumenta di 0.0.1. La 1.0.0 sarà la prima versione ufficiale.

## [0.0.8] — 2026-11-07
- **Anteprima delle carte**: ogni carta (mano, in gioco, area di minaccia, mazzo, scarti, ricerca, scheda della guida e investigatore) ha una miniatura col colore della classe e il costo; toccandola si apre la carta disegnata con testo, icone, tratti, slot, Salute/Sanità e il link alla carta originale su ArkhamDB.
- **Import da ArkhamDB**: in «Il tuo mazzo» → «Importa da ArkhamDB», con link o numero del mazzo, JSON o testo esportato (Download → Text file). Carte fuori dal Set Base segnalate e saltate; debolezza base casuale sostituita; avviso se il mazzo è per un altro investigatore.
- Badge della versione sempre visibile anche su schermi stretti.

## [0.0.7] — 2026-11-07
- **Tavolo online**: dalla guida (menu ☰ → Tavolo online) si crea un tavolo su Supabase con un codice e un QR per ogni giocatore.
- **Schermata giocatore** (apri il link o inserisci il codice): scheda dell'investigatore con risorse, indizi, danni, orrori, azioni del turno, capacità, area di minaccia e compagni; destino della trama modificabile.
- **Carte**: supporti in gioco con utilizzi (munizioni, cariche, scorte…), danni/orrori sugli alleati, esaurita/pronta, conteggio degli slot; consultazione di tutte le carte giocatore del Set Base in italiano; modifica del mazzo.
- **Mazzo digitale facoltativo**: mescola, mano iniziale con debolezze messe da parte, mulligan, pesca (mazzo vuoto → rimescola + 1 orrore), gioca pagando il costo, investi, scarta, debolezze pescate.
- **Sacchetto del caos condiviso**: chiunque peschi, gli altri vedono l'avviso.
- Sincronizzazione in tempo reale; «Annulla» della guida annulla solo le proprie modifiche.
- Backend separato da Four Against (tabelle e funzioni `ah_`), schema in `supabase/schema.sql`.

## [0.0.6] — 2026-11-07
- Numero di versione mostrato in alto, accanto al titolo (tolto da menu e Regole).

## [0.0.5] — 2026-11-07
Prima versione numerata. Contiene:
- Preparazione guidata (generale e per scenario, con le annotazioni del Diario della Campagna).
- Guida passo passo alle fasi del round: Miti, Investigatori, Nemici, Gestione.
- Contatori di destino/soglia, indizi del capitolo, risorse, indizi, danni, orrori e azioni per investigatore.
- Carica partita: salvataggi multipli, rinomina, elimina, esporta/importa con codice o file.
- Sacchetto del caos con icone disegnate e animazione di estrazione.
- Regole rapide, registro eventi, annulla.
