## Comportamento locale (ogni robot, per step)
- Stato iniziale: MOVING, LED verde, broadcast RAB data[1]=0.
- Conta i vicini fermi entro MAXRANGE (CountRAB).
- Calcola Ps = min(PSmax, S + alpha * N) e Pw = max(PWmin, W − beta * N).
- Se MOVING:
  - evita ostacoli se necessario, altrimenti va dritto,
  - con probabilità Ps passa a STOPPED.
- Se STOPPED:
  - LED rosso, broadcast RAB data[1]=1, ruote ferme,
  - con probabilità Pw passa a MOVING.
- Comunicazione: ogni robot invia nello RAB il proprio bit di stato (0=mv, 1=stopped).

## Comportamento collettivo atteso (emergente)
- Fase iniziale: robot sparsi si muovono casualmente.
- Nucleazione: occasionalmente alcuni si fermano per Ps spontanea; questi attirano altri (Ps aumenta con N).
- Crescita degli aggregati: gruppi fermi aumentano di dimensione perché Pw diminuisce con N e Ps cresce.
- Stabilizzazione: si formano uno o più aggregati stabili (dipende da parametri e densità).
- Dinamica: con parametri scelti (W=0.1, S=0.01, alpha=0.1, beta=0.05, MAXRANGE=30cm) ci si aspetta aggregati stabili dopo un po’ di tempo; alcuni robot continueranno a muoversi e a formare nuovi nuclei.

## Cosa osservare in ARGoS
- LED: zone rosse indicano aggregati; verdi indicano robot in movimento.
- Numero e dimensione degli ammassi (cluster): cresce nel tempo fino a stabilità.
- Mobilità residua: frazione di robot ancora in movimento.
- Possibili oscillazioni se Pw non è abbastanza bassa o Ps troppo bassa.

## Parametri critici e come influenzano il risultato
- MAXRANGE: più grande → ogni robot "vede" più fermi → aggregazione più veloce/ampia.
- alpha (influenza su Ps): maggiore → fermi inducono più fermate (nucleazione più facile).
- beta (influenza su Pw): maggiore → esseri fermi riducono più fortemente la ripartenza (aggregati più stabili).
- S e W (spontaneità): aumentandoli aumenta rumore e ricambio negli stati.
- PSmax / PWmin limitano gli estremi.