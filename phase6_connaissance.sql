-- ============================================================
-- PHASE 6 : états d'information des décideurs (fog of war)
-- Pour chaque décision majeure : ce que le décideur savait, depuis
-- quand, par quel canal, et si c'était exact. Support direct de F3 :
-- une décision ne se juge qu'à l'aune de l'information disponible.
-- ============================================================

INSERT INTO knowledge_states (decision_id,item,known_since_ts,via,accuracy,notes) VALUES
 -- D0 (plan de recherche, 04:30, Nagumo)
 ('DC-IJN-D0-SEARCH','Aucune force navale US attendue dans la zone (les PA US sont supposés à Pearl ou au sud)','1942-06-03T00:00:00-12:00','hypothèse (planification MI; renseignement périmé)','wrong','L''hypothèse fondatrice fausse de toute l''opération'),
 ('DC-IJN-D0-SEARCH','La surprise stratégique est acquise','1942-06-03T00:00:00-12:00','hypothèse','wrong','HYPO lit JN-25: les US attendent depuis des jours'),
 ('DC-IJN-D0-SEARCH','Catapulte du Tone défaillante (lancement n°4 retardé)','1942-06-04T04:30:00-12:00','observation bord','exact',NULL),
 -- D1 (réarmement vers Midway, 07:15, Nagumo)
 ('DC-NAGUMO-D1','Une 2e frappe sur Midway est nécessaire (Tomonaga)','1942-06-04T07:00:00-12:00','MSG-0604-0700-TOMONAGA','exact','Les pistes de Midway restaient utilisables'),
 ('DC-NAGUMO-D1','Attaques aériennes continues en provenance de Midway (TBF/B-26 à 07:10)','1942-06-04T07:05:00-12:00','observation directe','exact','Pression psychologique majeure'),
 ('DC-NAGUMO-D1','Aucun contact naval ennemi (recherches parties depuis ~2h30)','1942-06-04T07:15:00-12:00','absence de rapport','wrong','TF-16 lançait depuis 07:06 à ~130 nm; la ligne n°4 n''avait pas fini son aller'),
 ('DC-NAGUMO-D1','Doctrine: garder une réserve anti-navire armée (consigne de Yamamoto)','1942-06-03T00:00:00-12:00','doctrine','exact','D1 viole partiellement cette consigne'),
 -- D2 (suspension, 07:45, Nagumo)
 ('DC-IJN-D2-SUSPEND','10 navires ennemis, relèvement 010, 240 nm de Midway, cap 150, +20 nds','1942-06-04T07:45:00-12:00','CR-TONE4-0728','approximate','Position approximative; composition incomplète (pas de PA mentionné)'),
 ('DC-IJN-D2-SUSPEND','Composition de la force inconnue — PA possible mais non confirmé','1942-06-04T07:45:00-12:00','déduction','approximate','D''où la demande de précision au Tone n°4'),
 ('DC-IJN-D2-SUSPEND','Réarmement T->B avancé d''environ un tiers à moitié','1942-06-04T07:45:00-12:00','état bord','exact','Taux exact débattu (cf. controverse §4.3)'),
 -- D3 (récupérer d'abord, ~08:55, Nagumo)
 ('DC-IJN-D3-RECOVER','Un porte-avions accompagne la force US','1942-06-04T08:30:00-12:00','CR-TONE4-0820','approximate','Sous-estimation: 3 PA présents (puis un 4e signalement le confondra)'),
 ('DC-IJN-D3-RECOVER','Yamaguchi recommande de lancer immédiatement les D3A disponibles','1942-06-04T08:30:00-12:00','MSG-0604-0830-YAMAGUCHI','exact',NULL),
 ('DC-IJN-D3-RECOVER','La frappe Tomonaga orbite, carburant bas, blessés à bord','1942-06-04T08:37:00-12:00','observation directe','exact','Récupérer = sacrifier la fenêtre; ne pas récupérer = sacrifier des équipages'),
 ('DC-IJN-D3-RECOVER','Les attaques US du matin ont toutes échoué sans toucher un navire','1942-06-04T08:30:00-12:00','observation directe','exact','Renforce la confiance dans la CAP et la doctrine de frappe massive'),
 ('DC-IJN-D3-RECOVER','Une frappe coordonnée complète peut partir vers 10:30-11:00','1942-06-04T08:55:00-12:00','estimation état-major (Genda)','approximate','Sous-estime la saturation du cycle CAP/ponts'),
 -- U2 (lancement à distance limite, 07:00, Spruance)
 ('DC-USN-U2-LAUNCH','2 CV + cuirassés à 320/180 de Midway, cap 135, 25 nds','1942-06-04T06:03:00-12:00','CR-0604-0552-PBY','wrong','Position erronée de ~30-40 nm; 2 CV signalés sur 4'),
 ('DC-USN-U2-LAUNCH','La KB devra récupérer sa frappe Midway vers 08:30-09:30 (fenêtre de vulnérabilité)','1942-06-04T06:30:00-12:00','estimation état-major (Browning)','exact','Le calcul central de la matinée — correct'),
 ('DC-USN-U2-LAUNCH','155 nm = portée limite des TBD avec retour','1942-06-04T07:00:00-12:00','doctrine/performances','exact','Accepté en connaissance de cause'),
 ('DC-USN-U2-LAUNCH','2 CV japonais non localisés','1942-06-04T06:03:00-12:00','déduction (4 attendus par le renseignement)','exact','Le renseignement HYPO donnait 4-5 PA'),
 -- U4 (cap du Hornet, 07:55, Ring)
 ('DC-USN-U4-RING','Position rapportée de la KB (via TF-16)','1942-06-04T06:30:00-12:00','CR-0604-0552-PBY','wrong',NULL),
 ('DC-USN-U4-RING','Hypothèse: les 2 CV manquants opèrent séparément, plus au nord-ouest','1942-06-04T07:30:00-12:00','hypothèse (Mitscher/Ring)','wrong','Les 4 CV opéraient ensemble; hypothèse à l''origine du cap controversé'),
 -- U5 (prolonger la recherche, 09:55, McClusky)
 ('DC-USN-U5-MCCLUSKY','Océan vide au point d''interception calculé','1942-06-04T09:20:00-12:00','observation directe','exact','La KB a ralenti/manœuvré sous les attaques: l''estime US la projette trop loin'),
 ('DC-USN-U5-MCCLUSKY','Carburant: ~30-40 min de marge avant le point de non-retour','1942-06-04T09:30:00-12:00','jauges','exact','Plusieurs SBD amerriront au retour'),
 ('DC-USN-U5-MCCLUSKY','Destroyer isolé en route NE à grande vitesse (Arashi)','1942-06-04T09:55:00-12:00','observation directe','exact','Interprété correctement comme rejoignant la force principale'),
 -- U7 (pas de poursuite de nuit, 19:07, Spruance)
 ('DC-USN-U7-NOPURSUIT','3-4 CV japonais détruits ou en flammes','1942-06-04T18:00:00-12:00','rapports de pilotes','approximate','Décomptes confus mais ordre de grandeur correct'),
 ('DC-USN-U7-NOPURSUIT','Cuirassés et croiseurs japonais intacts, position inconnue, à l''ouest','1942-06-04T19:00:00-12:00','déduction','exact','C''était précisément le piège préparé par Yamamoto'),
 ('DC-USN-U7-NOPURSUIT','Les TF US n''ont aucun entraînement au combat de nuit comparable à l''IJN','1942-06-04T19:00:00-12:00','doctrine','exact',NULL),
 ('DC-USN-U7-NOPURSUIT','Mission prioritaire: couvrir Midway, pas anéantir la flotte','1942-06-02T12:00:00-12:00','ordres de Nimitz (calculated risk)','exact','La directive du "risque calculé" encadre toute la décision');
