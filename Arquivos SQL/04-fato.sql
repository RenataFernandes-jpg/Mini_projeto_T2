USE dw_pata_amiga;

INSERT INTO fato_pedido (
    numero_pedido,
    sk_tempo_pedido,
    sk_tempo_entrega,
    sk_loja,
    sk_categoria,
    houve_desconto,
    canal_pedido,
    dt_pedido,
    qt_itens,
    vl_liquido,
    dias_integracao_separacao,
    dias_separacao_nota,
    dias_nota_despacho,
    dias_despacho_entrega,
    dias_total_ate_entrega
)
SELECT
    p.numero_pedido,

    /* 1. DATA DO PEDIDO -> AAAAMMDD */
    CAST(
        DATE_FORMAT(p.dt_pedido, '%Y%m%d')
        AS SIGNED
    ) AS sk_tempo_pedido,

    /* 2. DATA DA ENTREGA 'Se ainda não entregou -> -1' */
    CASE
        WHEN p.data_entrega_cliente IS NULL THEN -1
        ELSE CAST(
            DATE_FORMAT(p.data_entrega_cliente, '%Y%m%d')
            AS SIGNED
        )
    END AS sk_tempo_entrega,

    /* 3. LOJA 'se o LEFT JOIN não encontrar -> -1' */
    COALESCE(dl.sk_loja, -1) AS sk_loja,

    /* 4. CATEGORIA 'se não encontrar -> -1' */
    COALESCE(dc.sk_categoria, -1) AS sk_categoria,
    
    /* 5. DESCONTO*/
    p.houve_desconto AS houve_desconto,
    
      /* 6. CANAL*/
    p.canal_pedido AS canal_pedido,
    
    /* 7. DATA/HORA ORIGINAL DO PEDIDO */
    p.dt_pedido AS dt_pedido,

    /* 8. QUANTIDADE DE ITENS '' e '-' -> NULL */
    CAST(
        NULLIF(NULLIF(TRIM(p.qt_itens), ''),'-'
        )
        AS UNSIGNED
    ) AS qt_itens,

    /* 9. VALOR LÍQUIDO */
    p.vl_liquido AS vl_liquido,

    /* 10. INTEGRAÇÃO -> SEPARAÇÃO */
    CASE
        WHEN p.data_hora_integracaoERP IS NULL
          OR p.data_separacao_estoque IS NULL
            THEN NULL
        ELSE DATEDIFF(
            p.data_separacao_estoque,
            DATE(p.data_hora_integracaoERP)
        )
    END AS dias_integracao_separacao,

    /* 11. SEPARAÇÃO -> NOTA */
    CASE
        WHEN p.data_separacao_estoque IS NULL
          OR p.data_nota_fiscal IS NULL
            THEN NULL
        ELSE DATEDIFF(
            p.data_nota_fiscal,
            p.data_separacao_estoque
        )
    END AS dias_separacao_nota,

    /* 12. NOTA -> DESPACHO */
    CASE
        WHEN p.data_nota_fiscal IS NULL
          OR p.data_despacho_transportadora IS NULL
            THEN NULL
        ELSE DATEDIFF(
            p.data_despacho_transportadora,
            p.data_nota_fiscal
        )
    END AS dias_nota_despacho,

    /* 13. DESPACHO -> ENTREGA */
    CASE
        WHEN p.data_despacho_transportadora IS NULL
          OR p.data_entrega_cliente IS NULL
            THEN NULL
        ELSE DATEDIFF(
            p.data_entrega_cliente,
            p.data_despacho_transportadora
        )
    END AS dias_despacho_entrega,

    /* 14. PEDIDO -> ENTREGA */
    CASE
        WHEN p.dt_pedido IS NULL
          OR p.data_entrega_cliente IS NULL
            THEN NULL
        ELSE DATEDIFF(
            p.data_entrega_cliente,
            DATE(p.dt_pedido)
        )
    END AS dias_total_ate_entrega

FROM limpo_pedido p

/* LOJA */
LEFT JOIN dim_loja dl
    ON TRIM(dl.cod_loja) = TRIM(p.cod_loja)

/* CATEGORIA */
LEFT JOIN dim_categoria dc
    ON dc.categoria_origem = p.categoria_produto
    ;

--  Roteiro das colunas:
--
--  * sk_tempo_pedido / sk_tempo_entrega: a chave e a data no formato AAAAMMDD.
--    Monte com CAST(DATE_FORMAT(<a data>, '%Y%m%d') AS SIGNED). A data do PEDIDO
--    vem no formato americano com AM/PM: a mascara e '%m/%d/%Y %h:%i %p'
--    (STR_TO_DATE). Usar '%d/%m/%Y' NAO da erro - ela devolve NULL e datas
--    erradas em silencio, que e pior. Os marcos da entrega ja vem em ISO:
--    DATE() basta. Entrega em branco -> -1.
--
--  * sk_loja, sk_categoria: vem de LEFT JOIN; se nao achou par, -1.
--
--  * LOJA (LEFT JOIN dim_loja): limpe o nome no ON. REPLACE tira '/SC' e o espaco
--    duplo; um CASE resolve 3 grafias (digitacao, apelido, abreviacao). Acento e
--    maiuscula nao atrapalham: a collation padrao do MySQL trata 'Timbo', 'TIMBO'
--    e 'Timbo' com acento como o mesmo texto.
--
--  * CATEGORIA (LEFT JOIN dim_categoria): uma linha so -
--    ON dc.categoria_origem = p.`CategoriaProduto`.
--
--  * houve_desconto e canal_pedido: padronize com CASE e grave na PROPRIA fato
--    (nao ha dimensao para eles). O de-para completo dos dois campos esta no
--    ENUNCIADO, na secao 7 ("Como padronizar o desconto e o canal").
--    A ordem importa: 'WHATSAPP' contem 'APP',
--    entao teste WHATS antes de APP.
--
--  * dinheiro e itens: '' e '-' viram NULL; tire "R$" e trate o milhar.
--
--  * os lags em dias: DATEDIFF(<fim>, <inicio>). Etapa nao cumprida grava NULL,
--    nunca 0. Use DATE() em volta da integracao (ela tem hora).

-- =====================================================================================
--  Confira o resultado com o 00-conferencia.sql (bloco "DEPOIS DO 04").
-- =====================================================================================
