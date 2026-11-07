# Note per Claude

- App in un unico file `index.html` (HTML/CSS/JS senza dipendenze). Testi in italiano.
- **Versionamento:** la versione è in `APP_VERSION` e nel meta `version` di `index.html`. Ogni modifica all'app aumenta la patch di 0.0.1 (0.0.5 → 0.0.6 → …): aggiorna entrambi i punti, aggiungi la voce in `CHANGELOG.md` e crea il tag git `vX.Y.Z` (dall'ambiente di Claude il push dei tag è bloccato: in quel caso lo crea Andrea da GitHub). Il passaggio alla 1.0.0 lo decide Andrea.
- Niente spoiler: non mostrare il retro di trame e capitoli né le risoluzioni.
- Le icone dei segnalini sono disegni originali: non sostituirle con le icone ufficiali FFG.
- Tavolo online: Supabase progetto `oxpccbmfnbxukgbrdodo`, condiviso con Four Against ma **tenere tutto separato**: solo oggetti con prefisso `ah_`, mai toccare `games`, `chars`, `log` o le funzioni di Four Against. Ogni modifica allo schema va anche in `supabase/schema.sql`.
- Carte: dati in `const CARDS` (da arkhamdb-json-data, testo italiano + nome inglese `en`). Niente scansioni ufficiali delle carte: l'anteprima è disegnata in HTML con link ad ArkhamDB.
