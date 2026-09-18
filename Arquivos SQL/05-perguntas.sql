USE dw_pata_amiga;

-- =====================================================================================
--  P1 - ONDE ESTA O GARGALO DO PROCESSO DE ENTREGA?
-- =====================================================================================


SELECT
    l.porte,

    ROUND(AVG(f.dias_total_ate_entrega), 2) AS tempo_medio_total,
    ROUND(AVG(f.dias_integracao_separacao), 2) AS integracao_separacao,
    ROUND(AVG(f.dias_separacao_nota), 2) AS separacao_nota,
    ROUND(AVG(f.dias_nota_despacho), 2) AS nota_despacho,
    ROUND(AVG(f.dias_despacho_entrega), 2) AS despacho_entrega,

    CASE
        WHEN AVG(f.dias_integracao_separacao) >= GREATEST(
            AVG(f.dias_separacao_nota),
            AVG(f.dias_nota_despacho),
            AVG(f.dias_despacho_entrega)
        )
        THEN 'Integração → Separação'

        WHEN AVG(f.dias_separacao_nota) >= GREATEST(
            AVG(f.dias_integracao_separacao),
            AVG(f.dias_nota_despacho),
            AVG(f.dias_despacho_entrega)
        )
        THEN 'Separação → Nota'

        WHEN AVG(f.dias_nota_despacho) >= GREATEST(
            AVG(f.dias_integracao_separacao),
            AVG(f.dias_separacao_nota),
            AVG(f.dias_despacho_entrega)
        )
        THEN 'Nota → Despacho'

        ELSE 'Despacho → Entrega'
    END AS gargalo

FROM fato_pedido f
JOIN dim_loja l
    ON f.sk_loja = l.sk_loja

WHERE f.sk_loja <> -1
  AND f.dias_total_ate_entrega IS NOT NULL

GROUP BY l.porte
ORDER BY l.porte;

-- =====================================================================================
--  P2 - QUAL CATEGORIA CONCENTRA O FATURAMENTO?
-- =====================================================================================

SELECT
    c.nome_categoria AS categoria,
    ROUND(SUM(f.vl_liquido), 2) AS faturamento,
    ROUND(
        SUM(f.vl_liquido) /
        (SELECT SUM(vl_liquido)
         FROM fato_pedido
         WHERE vl_liquido IS NOT NULL) * 100,
        2
    ) AS percentual_faturamento
FROM fato_pedido f
JOIN dim_categoria c
    ON f.sk_categoria = c.sk_categoria
WHERE f.vl_liquido IS NOT NULL
GROUP BY c.nome_categoria
ORDER BY faturamento DESC;


-- =====================================================================================
--  P3 - O DESCONTO FUNCIONA IGUAL EM TODO CANAL?
-- =====================================================================================

SELECT
    canal_pedido,
    houve_desconto,
    COUNT(*) AS qtd_pedidos,
    ROUND(AVG(vl_liquido), 2) AS ticket_medio
FROM fato_pedido
WHERE vl_liquido IS NOT NULL
GROUP BY
    canal_pedido,
    houve_desconto
ORDER BY
    canal_pedido,
    houve_desconto;
    
 -- participação do tipo de canal em cima do faturamento total   
SELECT
    canal_pedido,
    ROUND(SUM(vl_liquido), 2) AS faturamento,
    ROUND(
        SUM(vl_liquido) /
        (SELECT SUM(vl_liquido)
         FROM fato_pedido
         WHERE vl_liquido IS NOT NULL) * 100,
        2
    ) AS percentual_faturamento
FROM fato_pedido
WHERE vl_liquido IS NOT NULL
GROUP BY canal_pedido
ORDER BY faturamento DESC;
    

-- =====================================================================================
--  P4 - QUAL PRACA DE ATENDIMENTO CONCENTRA O FATURAMENTO?
-- =====================================================================================

SELECT
    p.cod_praca,
    p.nome_praca,
    ROUND(
        SUM(f.vl_liquido * b.fator_publico),
        2
    ) AS faturamento_rateado,
    ROUND(
        SUM(f.vl_liquido * b.fator_publico) /
        (
            SELECT SUM(vl_liquido)
            FROM fato_pedido
            WHERE vl_liquido IS NOT NULL
        ) * 100,
        2
    ) AS percentual_faturamento
FROM fato_pedido f
JOIN dim_loja l
    ON f.sk_loja = l.sk_loja
JOIN bridge_loja_praca b
    ON l.cod_loja = b.cod_loja
JOIN dim_praca p
    ON b.sk_praca = p.sk_praca
WHERE f.sk_loja <> -1
  AND f.vl_liquido IS NOT NULL
GROUP BY
    p.cod_praca,
    p.nome_praca
ORDER BY faturamento_rateado DESC;


-- =====================================================================================
--  P5 - ONDE ABRIR A PROXIMA LOJA, E O QUE OS DADOS NAO PERMITEM AFIRMAR?
-- =====================================================================================


SELECT
    l.cod_loja,
    l.nome_loja,
    l.cidade,
    l.porte,
    l.populacao_cidade,
    x.itens_vendidos,
    ROUND(
        x.itens_vendidos / l.populacao_cidade * 1000,
        2
    ) AS itens_por_mil_habitantes,
    ROUND(x.tempo_medio_entrega, 2) AS tempo_medio_entrega
FROM dim_loja l
JOIN (
    SELECT
        f.sk_loja,
        SUM(f.qt_itens) AS itens_vendidos,
        AVG(f.dias_total_ate_entrega) AS tempo_medio_entrega
    FROM fato_pedido f
    WHERE f.sk_loja <> -1
    GROUP BY f.sk_loja
) x
    ON l.sk_loja = x.sk_loja
WHERE l.populacao_cidade > 0
ORDER BY itens_por_mil_habitantes DESC;
