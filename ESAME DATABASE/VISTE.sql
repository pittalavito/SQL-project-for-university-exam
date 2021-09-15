CREATE VIEW STATISTIC_USER AS
SELECT 
	OA.num_conto         AS num_conto      ,
	OA.id_crypto         AS nome_crypto    , 
    count(OA.id)         AS num_operazioni ,
    sum(OA.importo_in)   AS tot_importo_in ,
    sum(OA.unita_crypto)*C.current_price AS tot_importo_out,
    "op_attuali"         AS tipo_op
FROM   OP_ATTUALI OA JOIN CRYPTO C ON C.nome = OA.id_crypto  
GROUP BY OA.num_conto , Oa.id_crypto 
UNION
SELECT
	OP.num_conto ,
    OP.id_crypto ,
    count(OP.id) ,
    sum(OP.importo_in),
    sum(OP.importo_out),
    "op_passate"
FROM  OP_PASSATE OP
GROUP BY OP.num_conto , OP.id_crypto ;