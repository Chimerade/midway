-- ============================================================
-- PHASE 10e : cibles des événements de repérage (pour visualiser
-- "qui voit qui" sur la carte — constat replay: les croisements
-- d'avions semblaient aveugles alors que les détections existent)
-- ============================================================
INSERT INTO event_participants VALUES
 ('EV-0603-0900-PBY','formations','TRANSPORT-GROUP','target'),
 ('EV-0604-0552-2CV','formations','KIDO-BUTAI','target'),
 ('EV-0604-0553-MIDWAYRADAR','ships','SH-MIDWAY','observer'),
 ('EV-0604-0728-TONE4','formations','TF-16','target'),
 ('EV-0604-0820-CARRIER','formations','TF-16','target');
