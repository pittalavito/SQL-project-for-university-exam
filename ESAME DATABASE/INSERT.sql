INSERT INTO UTENTE (username, password , nome , cognome , data_nascita )
    VALUES            
    ("mariorossi"   , 1234     , "mario"  ,"rossi"   , "2000-01-01"   ),
    ("salvobianchi" , 1234     , "salvo"  ,"bianchi" , "1991-08-28"   ),
    ("andreverdi"   , 1234     , "andrea" ,"verdi"   , "2005-05-14"   ),
    ("maraviola"    , 1234     , "mara"   ,"viola"   , "1988-07-13"   )
;

INSERT INTO MET_PAGAMENTO (numero_carta , circuito , id_utente)
    VALUES
    ("533312347895456" , "mastercard" , 1),
    ("123456789123456" , "visa"       , 1),
    ("231416214779980" , "visa"       , 2),
    ("489484293949824" , "mastercard" , 4)
;

INSERT INTO TRANSAZIONE (importo , numero_carta , num_conto ,tipo )
    VALUES
    (10000 ,533312347895456 , 1 , 0 ),
    (11500 ,123456789123456 , 1 , 0 ),
    (20500 ,231416214779980 , 2 , 0 ),
    (10500 ,231416214779980 , 2 , 0 ),
    (11110 ,489484293949824 , 3 , 0 ),
    (100  ,533312347895456 , 1 , 1 ),
    (150  ,123456789123456 , 1 , 1 ),
    (250  ,231416214779980 , 2 , 1 ),
    (150  ,231416214779980 , 2 , 1 ),
    (111  ,489484293949824 , 3 , 1 )
;

INSERT INTO CRYPTO (nome , symbol , disponibilita , current_price , max_supply , market_cap )
    VALUES
    ("bitcoin" , "BTC" , 21     , 46894.92 , 21000000    , 881808064021  ),
    ("cardano" , "ADA" , 500000 , 2.4      , 45000000000 , 76959632994   ),
    ("ethereum", "ETH" , 210    , 3397.26  , -1          , 397771919443  ),
    ("solana"  , "SOL" , 50000  , 159      , -1          , 47405307718   )
;

INSERT INTO DATI_STORICI ( id_crypto , data_d , max_price , min_price )
    VALUES
    ("bitcoin" , "2021-09-14"  , 47000 , 45000 ),
    ("cardano" , "2021-09-14"  , 2.6   , 2.4   ),
    ("ethereum", "2021-09-14"  , 3500  , 3200  ),
    ("solana"  , "2021-09-14"  , 180   , 149   ),
    ("bitcoin" , "2021-09-13"  , 44800 , 44000 ),
    ("cardano" , "2021-09-13"  , 2.7   , 2.6   ),
    ("ethereum", "2021-09-13"  , 3700  , 3600  ),
    ("solana"  , "2021-09-13"  , 190   , 165   )
;

INSERT INTO OSSERVA (id_utente , id_crypto)
    VALUES
    (1 , "bitcoin" ),
    (1 , "cardano" ),
    (2 , "ethereum"),
    (2 , "bitcoin" ),
    (2 , "solana"  ),
    (3 , "bitcoin" ),
    (3 , "cardano" ),
    (3 , "ethereum")
;

INSERT INTO PROMOZIONE (id_crypto , descrizione , sconto_comm , data_fine )
    VALUES
    ("bitcoin" , "sconto settembre 2021" , 30 , "2021-10-01"),
    ("solana"  , "sconto settembre 2021" , 30 , "2021-10-01"),
    ("cardano" , "sconto settembre 2021" , 30 , "2021-10-01")
;

INSERT INTO PROM_ATTIVA(num_conto , codice) VALUES (1,2),(2,1);

INSERT INTO OP_ATTUALI( id, num_conto , id_crypto ,unita_crypto ,importo_in, data_in )
    VALUES
    (1, 1 , "bitcoin" , 0.1 , 2000 ,"2020-12-09 00:00:00"),
    (2, 2 , "bitcoin" , 0.1 , 3000 ,"2020-11-09 00:00:00"),
    (3, 1 , "solana"  , 11  , 200 ,"2020-12-09 00:00:00"),
    (4, 2 , "solana"  , 21  , 400 ,"2020-05-09 00:00:00"),
    (5, 3 , "cardano" , 200 , 200 ,"2020-12-09 00:00:00"),
    (6, 3 , "bitcoin" , 0.1 , 2000 ,"2020-12-09 00:00:00"),
    (7, 1 , "bitcoin" , 0.1 , 2000,"2020-12-09 00:00:00"),
    (8, 2 , "bitcoin" , 0.1 , 3000 ,"2020-11-09 00:00:00"),
    (9 ,1 , "solana"  , 11  , 200 ,"2020-12-09 00:00:00"),
    (10,2 , "solana"  , 21  , 400 ,"2020-05-09 00:00:00"),
    (11,3 , "cardano" , 200 , 200 ,"2020-12-09 00:00:00"),
    (12,3 , "bitcoin" , 0.1 , 2000 ,"2020-12-09 00:00:00")
;

DELETE FROM OP_ATTUALI WHERE id IN (7 ,8 ,9 ,10 ,11 , 12 ,4);

