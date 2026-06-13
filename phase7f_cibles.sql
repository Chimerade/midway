-- ============================================================
-- PHASE 7f : cibles manquantes des événements d'attaque
-- (nécessaires pour localiser les animations de combat sur la carte
-- et, plus tard, pour le moteur F2: qui attaque qui, où, quand)
-- ============================================================
INSERT INTO event_participants VALUES
 ('EV-0603-1624-B17ATK','formations','TRANSPORT-GROUP','target'),
 ('EV-0604-0143-PBYTORP','formations','TRANSPORT-GROUP','target'),
 ('EV-0604-0143-PBYTORP','ships','SH-AKEBONO-MARU','target'),
 ('EV-0604-0710-TBFB26','formations','KIDO-BUTAI','target'),
 ('EV-0604-0755-VMSB','formations','KIDO-BUTAI','target'),
 ('EV-0604-0755-VMSB','ships','SH-HIRYU','target'),
 ('EV-0604-0810-B17','formations','KIDO-BUTAI','target'),
 ('EV-0604-0820-SB2U','formations','KIDO-BUTAI','target'),
 ('EV-0604-0820-SB2U','ships','SH-HARUNA','target'),
 ('EV-0604-0920-VT8','formations','KIDO-BUTAI','target'),
 ('EV-0604-0938-VT6','formations','KIDO-BUTAI','target'),
 ('EV-0604-1000-VT3','formations','KIDO-BUTAI','target'),
 ('EV-0604-0616-VMF221','ships','SH-MIDWAY','observer'),
 ('EV-0605-0800-FLEMING','formations','CRUDIV7','target'),
 ('EV-0605-0800-FLEMING','ships','SH-MIKUMA','target'),
 ('EV-0606-0800-STRIKE1','formations','CRUDIV7','target'),
 ('EV-0606-1045-STRIKE2','formations','CRUDIV7','target'),
 ('EV-0606-1330-STRIKE3','formations','CRUDIV7','target');
