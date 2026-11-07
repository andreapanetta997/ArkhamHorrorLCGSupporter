# Arkham Horror LCG Supporter

Versione attuale: **0.0.8** — vedi [CHANGELOG.md](CHANGELOG.md).

Web app (un solo file `index.html`, nessuna dipendenza) per guidare passo passo una partita ad **Arkham Horror: Il Gioco di Carte** — Set Base, campagna *La Notte della Zelota*.

## Cosa fa
- **Preparazione** guidata: checklist generale e dello scenario (tiene conto del Diario: casa, Ghoul Sacerdote, cultisti fuggiti, mezzanotte).
- **Round passo per passo**: Miti → Investigatori → Nemici → Gestione, con il primo round che salta i Miti.
- **Contatori**: destino (trama + altre carte) con soglia, indizi richiesti dal capitolo, risorse/indizi/danni/orrori per investigatore, azioni del turno (con le azioni extra di Daisy e Skids).
- Automatismi: +1 destino nei Miti, +1 risorsa a tutti in Gestione, 5 risorse iniziali, traumi come danni/orrori iniziali.
- **Sacchetto del caos** per difficoltà, effetti dei simboli dello scenario e pesca di prova.
- **Regole rapide** e promemoria degli Obblighi di trama/capitolo, senza spoiler sui retro.
- Annulla, registro eventi, salvataggio automatico nel browser.
- **Carica partita**: elenco delle partite salvate sul dispositivo, rinomina, elimina, esporta/importa tramite codice o file `.arkham.json` per continuare su un altro dispositivo.

## Tavolo online
La guida crea il tavolo dal menu ☰ → **Tavolo online**: ogni giocatore riceve un codice (o un QR / link `?codice=XXXXXX`) e gestisce dal proprio telefono la sua scheda, le carte in gioco, l'area di minaccia e, se vuole, un mazzo digitale. Destino e sacchetto del caos sono condivisi.

- Backend: Supabase, nello stesso progetto di Four Against ma con tabelle e funzioni separate (prefisso `ah_`). Tabelle con RLS attivo e senza policy: si accede solo tramite funzioni che richiedono il codice della guida (salvato come hash) o il codice del giocatore. Schema in `supabase/schema.sql`.
- La sincronizzazione usa un segnale vuoto sul canale Realtime `ah-<id>`; i dati si rileggono tramite le funzioni.
- Il progetto Supabase gratuito va in pausa dopo 7 giorni senza attività: se serve, riattivalo dalla dashboard prima di giocare.
- Funziona dal sito GitHub Pages (non dall'anteprima in chat di Claude, che blocca le connessioni esterne).
- Dati delle carte: ArkhamDB (arkhamdb-json-data), testo italiano.

## Uso
Apri `index.html` nel browser (telefono o PC). Con GitHub Pages attivo sul branch `main` è raggiungibile online.
