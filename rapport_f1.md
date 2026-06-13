# Rapport F1 — replay du 4 juin à travers le modèle de contraintes
Run 2026-06-13T09:22:43+00:00 — 13 vérifications : 0 incohérences, 2 tensions, 7 cohérentes, 4 bornes contre-factuelles

## [~] AKAGI — Retour bombe->torpille (D2) — fin théorique sans interruption
- Historique : P&T: encore incomplet à 10:20; bombes non rangées
- Modèle : fin à 08:43 (2 vagues de 10 équipes × 29 min) (marge +97 min)
- Entrées : PT-REARM-B5N-B2T, événements dattaque 07:55-10:15

Sans interruption, le modèle finit à 08:43 — or les sources disent 'incomplet à 10:20'. L'écart mesure l'effet des interruptions réelles (alertes, CAP, manœuvres évasives 07:55-10:15): le modèle F2 devra inclure un facteur d'indisponibilité des équipes sous attaque (~40-60%). L'étape 'rangement des bombes' sautée (process_steps) reste la clé de la vulnérabilité.

## [~] KAGA — Retour bombe->torpille (D2) — fin théorique sans interruption
- Historique : P&T: encore incomplet à 10:20; bombes non rangées
- Modèle : fin à 09:12 (3 vagues de 10 équipes × 29 min) (marge +68 min)
- Entrées : PT-REARM-B5N-B2T, événements dattaque 07:55-10:15

Sans interruption, le modèle finit à 09:12 — or les sources disent 'incomplet à 10:20'. L'écart mesure l'effet des interruptions réelles (alertes, CAP, manœuvres évasives 07:55-10:15): le modèle F2 devra inclure un facteur d'indisponibilité des équipes sous attaque (~40-60%). L'étape 'rangement des bombes' sautée (process_steps) reste la clé de la vulnérabilité.

## [✓] KB (4 ponts) — Lancement frappe Tomonaga
- Historique : 04:30 -> 04:45 (15 min)
- Modèle : 14 min/pont (27 appareils, 20 s/décollage) (marge +1 min)
- Entrées : carrier_constraints.launch_interval_s, events EV-0604-0430/0445

27 appareils/pont à 20 s + mise au vent ~5 min = 14 min, dans la fenêtre historique de 15 min.

## [✓] Enterprise — Lancement groupe complet (2 deckloads)
- Historique : 07:06 -> ~08:06 (60 min)
- Modèle : 52 min (15 + re-spot 25 + 11) (marge +8 min)
- Entrées : carrier_constraints US, mission MS-0604-CV6AM

Le lancement déferré historique (~1 h) correspond au modèle: 33 SBD (15 min), re-spot (~25 min), puis TBD+escorte (11 min). C'est ce délai qui a séparé les escadrilles en route.

## [✓] KB (4 ponts) — Récupération frappe Tomonaga + CAP
- Historique : 08:37 -> 09:10 (33 min)
- Modèle : 20 min/pont (25 appontages à 35 s) (marge +13 min)
- Entrées : recovery_interval_s, events EV-0604-0837/0910

~25 appontages/pont à 35 s + mise au vent = 20 min < 33 min historiques. La marge (13 min) couvre les appareils endommagés qui bloquent le pont.

## [✓] AKAGI — Réarmement D1 torpille->bombe, avancement à 07:45
- Historique : comptes rendus: "environ un tiers à la moitié"
- Modèle : 11/18 avions traités en 30 min (10 équipes, 28 min/avion)
- Entrées : PT-REARM-B5N-T2B, arming_crews

Le modèle (10 équipes en parallèle, cycle 28 min) donne 11/18 au moment du contre-ordre — conforme à la fourchette des témoignages. Valide le paramétrage des équipes.

## [✓] KAGA — Réarmement D1 torpille->bombe, avancement à 07:45
- Historique : comptes rendus: "environ un tiers à la moitié"
- Modèle : 11/27 avions traités en 30 min (10 équipes, 28 min/avion)
- Entrées : PT-REARM-B5N-T2B, arming_crews

Le modèle (10 équipes en parallèle, cycle 28 min) donne 11/27 au moment du contre-ordre — conforme à la fourchette des témoignages. Valide le paramétrage des équipes.

## [✓] Hiryū — Contre-attaque Kobayashi lancée 10:54
- Historique : lancement historique 10:54 (18 D3A + 6 A6M)
- Modèle : spot d'un demi-groupe: 35 min -> début nécessaire ~10:14
- Entrées : PT-SPOT-IJN, EV-0604-1054-HIRYU1

Pour lancer à 10:54, le spot devait commencer vers 10:14 — c'est-à-dire AVANT les coups de 10:22 sur les autres porte-avions. Cohérent avec les sources: Yamaguchi préparait déjà sa frappe. Le modèle confirme que la réactivité du Hiryū n'a rien de miraculeux: elle était déjà engagée.

## [✓] Yorktown — Lancement du groupe (17 VB-3 + 12 VT-3 + 6 VF-3)
- Historique : 08:38 -> 09:06 (28 min)
- Modèle : 19 min (marge +9 min)
- Entrées : carrier_constraints SH-CV5, MS-0604-CV5AM

35 appareils max au spot (36), 29 lancés à 28 s: 19 min — dans la fenêtre. Le départ groupé et la navigation directe (contrairement au Hornet) expliquent l'arrivée simultanée avec McClusky malgré 1h30 de retard au lancement.

## [≈] KB — Frappe anti-navire: 1er lancement faisable — hyp. optimiste (ponts libres, CAP négligée)
- Historique : plan de Nagumo: 10:30; SBD frappent à 10:22
- Modèle : spot fini 10:00, frappe lancée 10:15 (marge -7 min)
- Entrées : PT-SPOT-IJN, PT-LAUNCH-IJN, fenêtre dattaques VT 09:20-10:15

Récupération finie 09:10; spot 50 min, lancement 15 min. Hypothèse optimiste (ponts libres, CAP négligée): lancement complet à 10:15 — AVANT 10:22: seul un déroulement parfait sans CAP aurait battu les SBD.

## [≈] KB — Frappe anti-navire: 1er lancement faisable — hyp. réaliste (ponts ~50% disponibles sous attaque continue)
- Historique : plan de Nagumo: 10:30; SBD frappent à 10:22
- Modèle : spot fini 10:32, frappe lancée 10:48 (marge +26 min)
- Entrées : PT-SPOT-IJN, PT-LAUNCH-IJN, fenêtre dattaques VT 09:20-10:15

Récupération finie 09:10; spot 50 min, lancement 15 min. Hypothèse réaliste (ponts ~50% disponibles sous attaque continue): lancement complet à 10:48 — 26 min APRÈS l'arrivée des SBD (10:22).

## [≈] KB — Frappe anti-navire: 1er lancement faisable — hyp. défavorable (ponts ~33% disponibles)
- Historique : plan de Nagumo: 10:30; SBD frappent à 10:22
- Modèle : spot fini 10:44, frappe lancée 10:59 (marge +37 min)
- Entrées : PT-SPOT-IJN, PT-LAUNCH-IJN, fenêtre dattaques VT 09:20-10:15

Récupération finie 09:10; spot 50 min, lancement 15 min. Hypothèse défavorable (ponts ~33% disponibles): lancement complet à 10:59 — 37 min APRÈS l'arrivée des SBD (10:22).

## [≈] Sōryū+Hiryū — Option Yamaguchi 08:30: frappe D3A immédiate sans escorte complète
- Historique : proposée 08:30, refusée (D3)
- Modèle : lancement ~09:16, arrivée sur TF-16/17 ~10:30
- Entrées : décision DC-IJN-D3-RECOVER, MSG-0604-0830-YAMAGUCHI

Les ponts de CarDiv2 étaient libres avant la récupération (08:37). Spot réduit (~35 min) + lancement: les ~34 D3A partent vers 09:16 et frappent vers 10:30 — avant la destruction de 10:22-10:26. C'est LE contre-factuel central à explorer en F3 (frappe non escortée vs CAP US intacte).
