DROP DATABASE IF EXISTS ESAME;
CREATE DATABASE ESAME;
USE ESAME;

-- UTENTE ----------------------------------------------------------------------------------------------------------------------
CREATE TABLE UTENTE(
    id           integer     primary key auto_increment ,
    username    varchar(30)  unique  not null ,
    password     varchar(30) not null,
    nome         varchar(30) not null,
    cognome      varchar(30) not null,
    data_nascita date        not null
)Engine="InnoDB";

-- CONTO TRADING ----------------------------------------------------------------------------------------------------------------------
CREATE TABLE CONTO_TRADING(
    num_conto integer primary key auto_increment ,
    saldo     numeric(10,2)  not null default 0  ,
    id_utente integer unique not null            ,
     
    constraint CHK_CONTO_TRADING check(saldo >= 0),
    
    index idx_id_utente_met_pag(id_utente),
    foreign key(id_utente) references utente(id) on update no action on delete cascade
)Engine="InnoDB";

DELIMITER //
CREATE TRIGGER AFTER_INSERT_ON_CONTO_TRADING
AFTER INSERT ON CONTO_TRADING
FOR EACH ROW
BEGIN
    IF NOT EXISTS ( 
        SELECT DATEDIFF( current_date , data_nascita ) AS ETA 
        FROM UTENTE WHERE id = NEW.id_utente
        HAVING ETA >= 18*365
    ) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Errore: utente ancora minorenne";
    END IF;
END //
DELIMITER ;

-- MET_PAGAMENTO ----------------------------------------------------------------------------------------------------------------------
CREATE TABLE MET_PAGAMENTO(
    numero_carta numeric(16,0) primary key ,
    circuito     varchar(30)   not null,
    id_utente    integer       not null,

    index idx_id_utente_met_pag(id_utente),
    foreign key(id_utente) references utente(id) on update cascade on delete cascade
)Engine="InnoDB";

DELIMITER //
CREATE TRIGGER AFTER_INSERT_ON_MET_PAGAMENTO
AFTER INSERT ON MET_PAGAMENTO
FOR EACH ROW
BEGIN
    DECLARE VAR_I   INTEGER; /*NUMERO METODI DI PAGAMENTO*/
    DECLARE VAR_ETA INTEGER;

    SELECT count(*) into VAR_I
    FROM   MET_PAGAMENTO 
    WHERE  id_utente = NEW.id_utente;

    IF( VAR_I > 3 ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Errore: ogni utente puo avere al massimo 3 metodi di pagamento";
    END IF;
    
    IF( VAR_I = 1 ) THEN
        IF EXISTS ( 
            SELECT DATEDIFF( current_date , data_nascita ) AS ETA 
            FROM UTENTE WHERE id = NEW.id_utente
            HAVING ETA >= 18*365
        ) 
			THEN INSERT INTO CONTO_TRADING ( id_utente ) VALUES (NEW.id_utente);
			ELSE   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Errore: utente ancora minorenne";
        END IF ;
    END IF;

END //
DELIMITER ;

-- TRANSAZIONE ----------------------------------------------------------------------------------------------------------------------
CREATE TABLE TRANSAZIONE(
    id           integer       primary key auto_increment ,
    data_t       timestamp     not null default current_timestamp ,
    importo      numeric(10,2) not null ,
    numero_carta numeric(16,0) not null ,
    num_conto    integer       not null ,
    tipo         boolean                ,/*0=deposito , 1=prelievo*/

    index idx_numero_carta_transazione(numero_carta),
    index idx_num_conto_transazione(num_conto),
    foreign key(num_conto)    references conto_trading(num_conto) on update cascade on delete cascade ,
    foreign key(numero_carta) references met_pagamento(numero_carta) on update cascade on delete cascade 
)Engine="InnoDB";

DELIMITER // 
CREATE TRIGGER AFTER_INSERT_ON_TRANSAZIONE
AFTER INSERT ON TRANSAZIONE 
FOR EACH ROW
BEGIN
    DECLARE VAR_IMPORTO NUMERIC(10,2);
    
    IF NOT EXISTS(
        SELECT *
        FROM   CONTO_TRADING CT JOIN MET_PAGAMENTO MP ON CT.id_utente = MP.id_utente
        WHERE  CT.num_conto = NEW.num_conto AND MP.numero_carta = NEW.numero_carta
    )
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Errore : il conto trading non appartiene all'utente a cui appartiene il metodo di pagamento";
    END IF;
    
    IF(NEW.importo < 50)
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Errore : il deposito minimo è di 50 $ ";
    END IF;

    IF( NEW.tipo = 1 AND NEW.importo > ( SELECT saldo FROM CONTO_TRADING WHERE num_conto = NEW.num_conto ) ) 
    THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Errore : saldo insufficiente ";
    END IF;
    
    SET VAR_IMPORTO = CASE 
        WHEN NEW.tipo = 0 THEN  NEW.importo 
        WHEN NEW.tipo = 1 THEN -NEW.importo 
    END;

    UPDATE CONTO_TRADING SET saldo = saldo + VAR_IMPORTO WHERE num_conto = NEW.num_conto;
  
END //
DELIMITER ;

-- CRYPTO ----------------------------------------------------------------------------------------------------------------------
CREATE TABLE CRYPTO(
    nome          varchar(30)    primary key ,
    symbol        varchar(30)    unique      ,
    commissione   float not null default 3   ,
    disponibilita numeric(10,4)  default 0   ,
    current_price numeric(10,4)  default 0   ,
    max_supply    numeric(20,0)  default 0   ,
    market_cap    numeric(20,0)  default 0
)Engine="InnoDB";

-- DATI STORICI ------------------------------------------------------------------------------------------------------------------------
CREATE TABLE DATI_STORICI(
    id_crypto varchar(30)   not null,
    data_d    date          not null,
    max_price numeric(10,4) not null,
    min_price numeric(10,4) not null,

    constraint CHK_DATI_STORICI check(
        min_price > 0 AND 
        max_price > 0 AND
        max_price > min_price
    ),
    
    index idx_id_crypto_dati_storici(id_crypto),
    foreign key(id_crypto) references crypto(nome) on update cascade on delete cascade,
    primary key(id_crypto , data_d)
)Engine="InnoDB";

-- OSSERVA ----------------------------------------------------------------------------------------------------------------------
CREATE TABLE OSSERVA(
    id_utente integer     not null,
    id_crypto varchar(30) not null,

    index idx_id_utente_osserva(id_utente),
    index id_crypto_osserva(id_crypto),
    foreign key(id_utente) references utente(id)   on update cascade on delete cascade,
    foreign key(id_crypto) references crypto(nome) on update cascade on delete cascade,
    primary key(id_crypto , id_utente)
)Engine="InnoDB";

-- PROMOZIONE CORRENTE --------------------------------------------------------------------------------------------------------------------
CREATE TABLE PROMOZIONE(
    codice       integer     primary key auto_increment,
    id_crypto    varchar(30) not null unique ,
    descrizione  varchar(30) not null    ,
    sconto_comm  float       not null    ,
    data_fine    timestamp   not null    ,
    data_inizio  timestamp   not null default current_timestamp ,
    
    constraint CHK_PROMOZIONE check( sconto_comm >= 0 AND sconto_comm <=100 ),

    index idx_id_crypto_promozione(id_crypto),
    foreign key(id_crypto) references crypto(nome) on update cascade on delete cascade
)Engine="InnoDB";

-- PROM ATTIVA --------------------------------------------------------------------------------------------------------------------
CREATE TABLE PROM_ATTIVA(
    num_conto integer primary key,
    codice    integer not null,

    index idx_num_conto_prom_attiva(num_conto),
    index idx_codice_prom_attiva(codice),
    foreign key(num_conto) references conto_trading(num_conto) on update cascade on delete cascade,
    foreign key(codice) references promozione(codice) on update cascade on delete cascade
)Engine="InnoDB";

-- OP_ATTUALI ----------------------------------------------------------------------------------------------------------------------
CREATE TABLE OP_ATTUALI(
    id           integer       primary key auto_increment,
    num_conto    integer       not null ,
    id_crypto    varchar(30)   not null ,
    unita_crypto numeric(20,4) not null ,
    importo_in   numeric(10,2) not null ,
    data_in      timestamp     not null default current_timestamp,

    constraint CHK_OP_ATTUALI check(importo_in >= 5 AND unita_crypto > 0 ),

    index idx_num_conto_op_attuali(num_conto),
    index idc_id_crypto_op_attuali(id_crypto),
    foreign key(num_conto) references conto_trading(num_conto) on update cascade on delete cascade, 
    foreign key(id_crypto) references crypto(nome) on update cascade on delete cascade
)Engine="InnoDB";

DELIMITER //
CREATE TRIGGER AFTER_INSERT_ON_OP_ATTUALI
AFTER INSERT ON OP_ATTUALI
FOR EACH ROW
BEGIN
    DECLARE VAR_DISPONIBILITA NUMERIC(20,10);

    SELECT disponibilita into VAR_DISPONIBILITA FROM CRYPTO WHERE  Nome = NEW.id_crypto ;

    IF(VAR_DISPONIBILITA < NEW.unita_crypto)
    THEN signal sqlstate '45000' SET MESSAGE_TEXT ="Errore: al momento non ci sono abbastanza unita disponibili per questo asset";
    ELSE 
        UPDATE CRYPTO SET disponibilita = disponibilita - NEW.unita_crypto WHERE nome = NEW.id_crypto;
        UPDATE CONTO_TRADING SET saldo = saldo - NEW.importo_in WHERE num_conto = NEW.num_conto;
    END IF;

END //
DELIMITER ;

---- qui devo sistemare ancora ---

DELIMITER //
CREATE TRIGGER AFTER_DELETE_ON_OP_ATTUALI
AFTER DELETE ON OP_ATTUALI
FOR EACH ROW
BEGIN
    DECLARE VAR_IMPORTO_OUT NUMERIC(10,2);
    
    SELECT OLD.unita_crypto*C.current_price into VAR_IMPORTO_OUT
    FROM   CRYPTO C
    WHERE  C.nome = OLD.id_crypto;

    UPDATE CRYPTO SET disponibilita = disponibilita + OLD.unita_crypto WHERE nome = OLD.id_crypto;
    
    INSERT INTO OP_PASSATE (id , num_conto    , id_crypto     , unita_crypto     , importo_in     , data_in     , importo_out    )
    VALUES  ( OLD.id , OLD.num_conto, OLD.id_crypto , OLD.unita_crypto , OLD.importo_in , OLD.data_in , VAR_IMPORTO_OUT);
    UPDATE CONTO_TRADING SET saldo = saldo + VAR_IMPORTO_OUT WHERE num_conto = OLD.num_conto;
END //
DELIMITER ;

-- OP PASSATE ----------------------------------------------------------------------------------------------------------------------
CREATE TABLE OP_PASSATE(
    id           integer       primary key ,
    num_conto    integer       not null ,
    id_crypto    varchar(30)   not null ,
    unita_crypto numeric(20,4) not null ,
    importo_in   numeric(10,2) not null ,
    importo_out  numeric(10,2) not null ,
    data_in      timestamp     not null ,
    data_out     timestamp     not null default current_timestamp,

    constraint CHK_OP_PASSATE check(
        importo_in   >= 5  AND
        importo_out  >  0   AND
        unita_crypto >  0
    ),

    index idx_num_conto_op_attuali(num_conto),
    index idc_id_crypto_op_attuali(id_crypto),
    foreign key(num_conto) references conto_trading(num_conto) on update cascade on delete cascade, 
    foreign key(id_crypto) references crypto(nome) on update cascade on delete cascade
)Engine="InnoDB";