-- ============================================================
-- PHASE 9 : paramètres de combat du moteur F2 (calibrés sur les
-- engagements réels du 4 juin — chaque valeur cite son calibrage)
-- ============================================================
INSERT INTO constraint_params VALUES
 ('P-SURV-DB-FULLCAP','combat','P(survie jusqu''au largage) bombardier en piqué vs CAP US alertée pleine force',0.40,'probabilité','triangular(0.25,0.40,0.55)','Frappe Kobayashi: 7/18 D3A parviennent à attaquer à travers ~12 F4F alertés par radar','SRC-YORKTOWN-AR'),
 ('P-SURV-TB-FULLCAP','combat','P(survie jusqu''au largage) torpilleur vs CAP US alertée',0.50,'probabilité','triangular(0.35,0.50,0.65)','Frappe Tomonaga: ~5/10 B5N larguent (escorte Zero engagée, CAP partiellement saturée)','SRC-YORKTOWN-AR'),
 ('P-SURV-DB-WEAKCAP','combat','P(survie) bombardier en piqué vs CAP désorganisée/au ras de l''eau',0.93,'probabilité','triangular(0.85,0.93,0.99)','10:22: ~47 SBD plongent, pertes avant largage quasi nulles (CAP japonaise à basse altitude après les VT)','SRC-SHATTERED-SWORD'),
 ('P-AA-US-KILL','combat','P(destruction par la DCA US d''un assaillant ayant passé la CAP), par passe',0.12,'probabilité','triangular(0.06,0.12,0.20)','Kobayashi: ~4 D3A supplémentaires abattus par la DCA de l''écran TF-17','SRC-YORKTOWN-AR'),
 ('P-LOSS-CV-ARMEDHANGAR','damage','P(perte du CV | >=1 bombe) avec hangars en double armement non rangé',0.90,'probabilité','beta(9,1)','Akagi: 1 bombe = fatale; Kaga: 4-5 = fatales; conditions du 4 juin matin (essence + munitions en hangar)','SRC-SHATTERED-SWORD'),
 ('P-LOSS-CV-1HIT','damage','P(perte | 1 bombe) hangars en configuration normale',0.12,'probabilité','triangular(0.05,0.12,0.25)','Base 1942: 1 bombe = incendie maîtrisable le plus souvent (cf. Shōkaku à Coral Sea)','SRC-SHATTERED-SWORD'),
 ('P-LOSS-CV-3HIT','damage','P(perte | 3+ bombes) configuration normale',0.55,'probabilité','triangular(0.35,0.55,0.75)','Yorktown: 3 bombes -> sauvé; Hiryū: 4 -> perdu (mais hangars actifs); Sōryū: 3 -> perdu (hangars armés)','SRC-SHATTERED-SWORD'),
 ('P-MISSIONKILL-CV-TORP2','damage','P(immobilisation | 2 torpilles)',0.95,'probabilité','beta(19,1)','Yorktown: 2 Type 91 = sans énergie, gîte, abandon','SRC-YORKTOWN-AR');
