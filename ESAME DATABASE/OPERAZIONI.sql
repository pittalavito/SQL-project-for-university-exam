-- OP_1 MOSTRA IL LISTINO ATTUALE DELLE CRYPTO OSSERVATE DA UN UTENTE (ok)
DELIMITER //
CREATE PROCEDURE OP_1( IN USERNAME VARCHAR(30))
BEGIN
    SELECT C.nome , C.current_price , C.market_cap , C.max_supply , C.market_cap/C.current_price AS circulating_supply
    FROM   CRYPTO C
    WHERE  C.nome IN (
        SELECT O.id_crypto
        FROM   OSSERVA O JOIN UTENTE U ON U.id = O.id_utente
        WHERE  U.username = USERNAME
    );
END //
DELIMITER ;

-- OP_2 MOSTRA L'IMPORTO TOTALE DEI PRELIEVI( O DEPOSITI ) CHE UN UTENTE HA ESEGUITO IN UN MESE DI UNO SPECIFICO ANNO
--     INDICANDONE ANCHE IL NUMERO DELLE OPERAZIONI ED IL NUMERO DEI METODI DI PAGAMENTO UTILIZZATI (ok)
DELIMITER //
CREATE PROCEDURE OP_2( IN USERNAME VARCHAR(30) , IN MESE INTEGER , IN ANNO INTEGER , IN TIPO BOOLEAN )
BEGIN
    SELECT sum(T.importo) AS TOT_IMPORTO , count(*) AS NUMERO_OPERAZIONI , count(distinct T.numero_carta) AS NUM_MET_PAGAMENTO_UTILIZZATI
    FROM   TRANSAZIONE T
    WHERE  year(T.data_t)  = ANNO AND 
           month(T.data_t) = MESE AND 
           T.tipo  = TIPO         AND
           T.num_conto IN (
        SELECT CT.num_conto
        FROM   UTENTE U JOIN CONTO_TRADING CT ON CT.id_utente = U.id 
        WHERE  U.username = USERNAME 
    );

END //
DELIMITER ;

-- OP_3 APRE UNA NUOVA OPERAZIONE DI TRADING , CONTROLLANDO CHE IL SALDO SIA MINORE DELL'IMPORTO CHE SI VUOLE INVESTIRE 
--     E METTENDO UNA COMMISSIONE AL PREZZO CORRENTE , SCONTANDO TALE COMMISSIONE QUALORA CI SIA UNA PROMOZIONE ATTIVA 
--     SUL CONTO TRADING DELL'UTENTE RELATIVA ALLA CRYPTO CHE VUOLE ACQUISTARE
DELIMITER //
CREATE PROCEDURE OP_3( IN NUM_CONTO INTEGER , IN CRYPTO VARCHAR(30) , IN IMPORTO NUMERIC(10,2))
BEGIN
   
    DECLARE VAR_SALDO         NUMERIC(10,2);
    DECLARE VAR_SCONTO        FLOAT;
    DECLARE VAR_CRYPTO        VARCHAR(30);
    DECLARE VAR_CURRENT_PRICE NUMERIC(20,10);
    DECLARE VAR_COMMISSIONE   FLOAT;

    SELECT C.saldo , P.id_crypto , P.sconto_comm into VAR_SALDO , VAR_CRYPTO , VAR_SCONTO
    FROM   CONTO_TRADING C LEFT JOIN (PROMOZIONE P JOIN PROM_ATTIVA PA ON PA.codice = P.codice ) ON C.num_conto = PA.num_conto  
    WHERE  C.num_conto = NUM_CONTO  ;
    
    IF( VAR_SALDO < IMPORTO ) THEN signal sqlstate '45000' SET MESSAGE_TEXT ="Errore: saldo insufficiente"; END IF;
    
    SELECT C.current_price ,C.commissione into VAR_CURRENT_PRICE , VAR_COMMISSIONE
    FROM   CRYPTO C
    WHERE  C.nome = CRYPTO;

    INSERT INTO OP_ATTUALI (num_conto , id_crypto , importo_in , unita_crypto)
    SELECT NUM_CONTO , CRYPTO , IMPORTO ,
        CASE
            WHEN VAR_CRYPTO IS NOT NULL AND VAR_CRYPTO = CRYPTO THEN IMPORTO/( VAR_CURRENT_PRICE*(1 +  VAR_COMMISSIONE*(1-VAR_SCONTO/100)/100 ))
            ELSE IMPORTO/( VAR_CURRENT_PRICE*(1 + VAR_COMMISSIONE/100) )
        END 
    ;

END //
DELIMITER ;

-- OP_4 ELENCA LE CRIPTOVALUTE SU CUI UN UTENTE HA O HA OPERATO IN PASSATO , INDICA ANCHE L'IMPORTO
--      TOTALE INIZIALMENTE  E L'IMPORTO ATTUALE , IL NUMERO DI OPERAZIONI PASSATE ED IL NUMERO DI 
--      OPERAZIONI ATTUALMENTE APERTE
DELIMITER //
CREATE PROCEDURE OP_4( IN USERNAME VARCHAR(30))
BEGIN
    SELECT 
	    us.nome_crypto,
	    count(us.num_operazioni)     AS tot_operazioni ,
        sum(us.tot_importo_in)       AS tot_importo_in , 
	    round(sum(us.tot_importo_out),2)     AS tot_importo_out,
        concat(round((sum(us.tot_importo_out)/sum(tot_importo_in) -1)*100,2) ,"%") AS P_L
    FROM statistic_user us
    WHERE us.num_conto IN (
        SELECT CT.num_conto
        FROM   CONTO_TRADING CT JOIN UTENTE U ON U.id = CT.id_utente
        WHERE  U.username = USERNAME
    ) 
    GROUP BY us.nome_crypto 
    ORDER BY P_L DESC;
END //
DELIMITER ;