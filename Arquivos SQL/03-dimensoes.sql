-- =====================================================================================
--  PASSO 1  - Rodar as dimensões
-- =====================================================================================
USE dw_pata_amiga;

/* 1. INSERINDO DADOS NA TABELA 'dim_praca*/
INSERT INTO dim_praca (cod_praca, nome_praca, regional, domicilios_com_pet)
SELECT DISTINCT 
   CodPraca,
   NomePraca,
   Regional,
   CAST(REPLACE(DomiciliosComPet, '.', '') AS unsigned) AS DomiciliosComPet
FROM stg_loja_praca;

/* 2. INSERINDO DADOS NA TABELA 'bridge_loja_praca' */
INSERT INTO bridge_loja_praca (cod_loja, sk_praca, fator_publico)
SELECT 
   l.CodLoja,
   p.sk_praca,
   l.PercentualPublico /
        SUM(l.PercentualPublico) OVER (
            PARTITION BY l.CodLoja
        ) AS fator_publico
FROM stg_loja_praca l 
JOIN dim_praca p ON l.CodPraca = p.cod_praca;

/* 3. INSERINDO DADOS NA TABELA 'dim_categorias' PARA O DE/PARA DA CATEGORIA */
INSERT INTO dim_categoria  VALUES
(-1, 'Nao Informado'         , 'Nao Informado'  , 'Nao Informado'),
(1, 'MEDICAMENTO'            , 'Medicamento'    , 'Saude e Higiene'),
(2, 'Racao Medicamentosa'    , 'Medicamento'    , 'Saude e Higiene'),
(3, 'Med.'                   , 'Medicamento'    , 'Saude e Higiene'),
(4, 'Medicamentos'           , 'Medicamento'    , 'Saude e Higiene'),
(5, 'RACAO'                  , 'Racao'          , 'Alimentacao'),
(6, 'ACESSORIO'              , 'Acessorio'      , 'Bem-estar'),
(7, 'Servico'                , 'Servico'        , 'Bem-estar'),
(8, 'brinquedo'              , 'Brinquedo'      , 'Bem-estar'),
(9, 'Rac.'                   , 'Racao'          , 'Alimentacao'),
(10, 'Petiscos'              , 'Petisco'        , 'Alimentacao'),
(11, 'Servicos'              , 'Servico'        , 'Bem-estar'),
(12, 'Higiene'               , 'Higiene'        , 'Saude e Higiene'),
(13, 'Petisco'               , 'Petisco'        , 'Alimentacao'),
(14, 'Acessorios'            , 'Acessorio'      , 'Bem-estar'),
(15, 'Racao Seca'            , 'Racao'          , 'Alimentacao'),
(16, 'Higiene e Beleza'      , 'Higiene'        , 'Saude e Higiene'),
(17, 'Brinquedos'            , 'Brinquedo'      , 'Bem-estar'),
(18, 'Hig.'                  , 'Higiene'        , 'Saude e Higiene');


/* 4. CRIANDO E INSERINDO DADOS NA TABELA 'dim_desconto' PARA O DE/PARA DO DESCONTO*/
DROP TABLE IF EXISTS dim_desconto;
CREATE TABLE dim_desconto (
    sk_desconto        INT PRIMARY KEY,
    origem             VARCHAR(20),
    corrigido          VARCHAR(30)
);
INSERT INTO dim_desconto VALUES
(-1, 'Nao informado'  , 'Nao informado' ),
( 1, 'S'              , 'Sim'           ),
( 2, 'SIM'            , 'Sim'           ),
( 3, '1'              , 'Sim'           ),
( 4, 'X'              , 'Sim'           ),
( 5, 'TRUE'           , 'Sim'           ),
( 6, 'V'              , 'Sim'           ),
( 7, 'N'              , 'Nao'           ),
( 8, 'NAO'            , 'Nao'           ),
( 9, '0'              , 'Nao'           ),
( 10, 'FALSE'         , 'Nao'           ),
( 11, 'F'             , 'Nao'           ),
( 12, ''              , 'Nao informado' );

-- Criando e inserindo dados na tabela 'dim_canal'
/* 5. CRIANDO E INSERINDO DADOS NA TABELA 'dim_canal' PARA O DE/PARA DO CANAL*/
DROP TABLE IF EXISTS dim_canal;
CREATE TABLE dim_canal (
    sk_canal      INT PRIMARY KEY,
    origem             VARCHAR(20),
    corrigido          VARCHAR(30)
);
INSERT INTO dim_canal VALUES
(-1, 'Nao informado'  , 'Nao informado' ),
( 1, 'WHATS'          , 'WhatsApp'      ),
( 2, 'APP'            , 'App'           ),
( 3, 'SITE'           , 'Site'          ),
( 4, 'LOJA'           , 'Loja Fisica'   ),
( 5, 'TELEFONE'       , 'Telefone'      ),
( 6, ''               , 'Nao informado' ),
( 7, 'App Pata Amiga' , 'App'           ),
( 8, 'Tel.'           , 'Telefone'      );


-- =====================================================================================
--  PASSO 2  - Copiar tabela e limpar dados errados
-- =====================================================================================


/* 1. CRIANDO E INSERINDO DADOS NA TABELA 'limpo_pedido'*/
DROP TABLE IF EXISTS limpo_pedido;
CREATE TABLE limpo_pedido AS 
SELECT
    `NumeroPedido`                 AS numero_pedido,
     STR_TO_DATE(NULLIF(`DtHoraPedido`, ''),        '%m/%d/%Y %h:%i %p') AS dt_pedido,
     STR_TO_DATE(NULLIF(`DtHoraIntegracaoERP`, ''), '%m/%d/%Y %h:%i %p') AS data_hora_integracaoERP,
    `Loja-Nome`                    AS nome_loja,
    `Cod Loja`                     AS cod_loja,
    `Bairro Entrega`               AS bairro_entrega,
    `CategoriaProduto`             AS categoria_produto,
    `FormaPagamento`               AS forma_pagamento,
    `QTD.Itens`                    AS qt_itens,
    `Qtd Unidades Devolvidas`      AS qtd_unidade_devolvidas,
    `NrItensCancelados`            AS num_itens_cancelados,
    `Peso Total (kg)`              AS peso_total,
    `ValorBrutoPedido(R$)`         AS valor_bruto_pedido,
    `Valor Desconto (R$)`          AS valor_desconto,    
     CASE WHEN TRIM(REPLACE(`ValorLiquidoPedido(R$)`,'R$','')) IN ('','-') THEN NULL
          WHEN `ValorLiquidoPedido(R$)` LIKE '%,%'
            THEN CAST(REPLACE(REPLACE(REPLACE(REPLACE(`ValorLiquidoPedido(R$)`,'R$',''),' ',''),'.',''),',','.')
               AS DECIMAL(15,2))
           ELSE CAST(REPLACE(REPLACE(`ValorLiquidoPedido(R$)`,'R$',''),' ','') AS DECIMAL(15,2)) END AS vl_liquido,
    HouveDesconto                AS houve_desconto,
    CanalPedido                  AS canal_pedido,
    STR_TO_DATE(NULLIF(`Dt Separacao Estoque`, ''), '%Y-%m-%d') AS data_separacao_estoque,
    STR_TO_DATE(NULLIF(`DtNotaFiscal`, ''), '%Y-%m-%d') AS data_nota_fiscal,
    STR_TO_DATE(NULLIF(`Dt_Despacho_Transportadora`, ''), '%Y-%m-%d') AS data_despacho_transportadora,
    STR_TO_DATE(NULLIF(`DtEntregaCliente`, ''), '%Y-%m-%d') AS data_entrega_cliente,
    `Valor Frete (R$)`             AS valor_frete,
    `TransportadoraResponsavel`    AS transportadora_responsavel,
    `SituacaoPedido`               AS situacao_pedido,
    `OBS`                          AS obs


FROM stg_pedido;


/* 2. ATUALIANDO A TABELA 'limpo_pedido' PARA A CORREÇÃO DA COLUNA CATEGORIA */
SET SQL_SAFE_UPDATES = 0;
UPDATE limpo_pedido lp
JOIN dim_categoria d
    ON TRIM(UPPER(lp.categoria_produto)) = TRIM(UPPER(d.categoria_origem))
SET lp.categoria_produto = nome_categoria;

/* 3. ATUALIANDO A TABELA 'limpo_pedido' PARA A CORREÇÃO DA COLUNA CANAL */
UPDATE limpo_pedido lp
JOIN dim_canal dc
    ON TRIM(UPPER(lp.canal_pedido)) = TRIM(UPPER(dc.origem))
SET lp.canal_pedido = dc.corrigido;

/* 3. ATUALIANDO A TABELA 'limpo_pedido' PARA A CORREÇÃO DA COLUNA DESCONTO */
UPDATE limpo_pedido lp
JOIN dim_desconto d
    ON TRIM(UPPER(lp.houve_desconto)) = TRIM(UPPER(d.origem))
SET lp.houve_desconto = d.corrigido;

/* 4. ATUALIANDO A TABELA 'limpo_pedido' PARA A CORREÇÃO DA COLUNA NOME DA LOJA */
UPDATE limpo_pedido
SET nome_loja = REGEXP_REPLACE(
    TRIM(REPLACE(nome_loja, '/SC', '')),' +',' '
);

UPDATE limpo_pedido
SET nome_loja = 
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    REPLACE(REPLACE(REPLACE(REPLACE(
        LOWER(nome_loja),
        'á', 'a'),
        'à', 'a'),
        'ã', 'a'),
        'â', 'a'),
        'é', 'e'),
        'ê', 'e'),
        'í', 'i'),
        'ó', 'o'),
        'ô', 'o'),
        'õ', 'o'),
        'ú', 'u'),
        'ü', 'u'),
        'ç', 'c'),
        'ñ', 'n');

UPDATE limpo_pedido
SET nome_loja = CASE

    WHEN nome_loja = 'pata amiga blumenal centro'
        THEN 'pata amiga blumenau centro'

    WHEN nome_loja = 'pata amiga floripa norte'
        THEN 'pata amiga florianopolis norte'

    WHEN nome_loja = 'pata amiga jgua do sul'
        THEN 'pata amiga jaragua do sul'

    ELSE nome_loja

END;

UPDATE limpo_pedido lp
JOIN dim_loja d
    ON TRIM(UPPER(lp.nome_loja)) = TRIM(UPPER(d.nome_loja))
SET lp.cod_loja = d.cod_loja
WHERE lp.cod_loja IS NULL
   OR TRIM(lp.cod_loja) = '';

SET SQL_SAFE_UPDATES = 1;

-- teste: ninguem pode ficar sem tradutor
SELECT t.categoria_produto
FROM   limpo_pedido t
LEFT   JOIN dim_categoria d ON d.categoria_origem = t.categoria_produto
WHERE  t.categoria_produto IS NULL;
-- 0 linhas
