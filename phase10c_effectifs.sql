-- ============================================================
-- PHASE 10c : effectifs manquants de 5 missions (constat replay:
-- pas de dénombrement affichable) + suppression du doublon
-- MS-0604-SEARCH-IJN (remplacé par les 7 lignes individuelles).
-- ============================================================
DELETE FROM missions WHERE mission_id='MS-0604-SEARCH-IJN';

INSERT INTO mission_squadrons VALUES
 ('MS-0603-B17','SQ-B17-MIDWAY',9,0,'ORD-500LB','9 B-17 (Sweeney) — aucun coup, aucune perte'),
 ('MS-0604-PBYNIGHT','SQ-PBY-MIDWAY',4,0,'ORD-MK13','4 PBY-5A radar; 1 torpille au but (Akebono Maru)'),
 ('MS-0606-STRIKE1','SQ-VB8',13,0,'ORD-1000LB','Composition approx. (26 SBD Hornet) — à préciser'),
 ('MS-0606-STRIKE1','SQ-VS8',13,0,'ORD-500LB',NULL),
 ('MS-0606-STRIKE2','SQ-VB6',10,0,'ORD-1000LB','31 SBD Enterprise (mix VB-6/VS-6/VB-3)'),
 ('MS-0606-STRIKE2','SQ-VS6',10,1,'ORD-500LB','1 SBD perdu (DCA)'),
 ('MS-0606-STRIKE2','SQ-VB3',11,0,'ORD-1000LB',NULL),
 ('MS-0606-STRIKE3','SQ-VB8',12,0,'ORD-1000LB','24 SBD Hornet'),
 ('MS-0606-STRIKE3','SQ-VS8',12,0,'ORD-500LB',NULL);
