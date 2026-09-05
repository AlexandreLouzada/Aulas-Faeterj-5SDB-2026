-- =====================================================================
-- GABARITO COMENTADO: EXERCÍCIOS DA UNIDADE 2
-- CURSO: SCRIPT DE BANCO DE DADOS (ORACLE DATABASE 23ai / APEX)
-- FOCO: SQL PARA ANÁLISE DE DADOS (FUNÇÕES ANALÍTICAS & CLÁUSULA OVER)
-- =====================================================================

-- ---------------------------------------------------------------------
-- CONTEXTUALIZAÇÃO PROFISSIONAL:
-- Ao contrário do GROUP BY tradicional, que "esmaga" as linhas de detalhe 
-- para gerar um único total agregador, as Funções Analíticas (cláusula OVER)
-- permitem realizar cálculos sobre um conjunto de registros sem perder a
-- individualidade de cada linha. Isso é indispensável para criar rankings,
-- calcular participações percentuais e analisar tendências e desvios.
-- ---------------------------------------------------------------------


-- =====================================================================
-- PARTE 1: NUMERAÇÃO E HISTÓRICO (ROW_NUMBER)
-- =====================================================================

-- QUESTÃO 1: JORNADA DE COMPRAS DO CLIENTE
-- Objetivo: Numerar cronologicamente cada compra realizada por cliente para 
-- analisar o comportamento de recompra e o intervalo entre pedidos (CRM).

SELECT 
    c.nome AS cliente, 
    v.dt_venda, 
    v.valor_liquido, 
    -- ROW_NUMBER() gera uma sequência numérica sequencial (1, 2, 3...)
    -- PARTITION BY faz a contagem reiniciar do 1 para cada id_cliente diferente
    -- ORDER BY garante que a sequência siga estritamente a ordem da data da venda
    ROW_NUMBER() OVER (
        PARTITION BY c.id_cliente 
        ORDER BY v.dt_venda
    ) AS numero_compra
FROM tb_venda v
JOIN tb_cliente c ON c.id_cliente = v.id_cliente
WHERE v.status = 'FECHADA'
ORDER BY c.nome, v.dt_venda;

-- Explicação Técnica: 
-- Se a "Ana" comprar hoje, amanhã e depois, o resultado mostrará 1, 2 e 3.
-- Se o "Bruno" comprar depois, a contagem dele reinicia em 1 graças ao PARTITION BY.


-- =====================================================================
-- PARTE 2: COMPETIÇÕES E RANKINGS (DENSE_RANK & PARTITION BY)
-- =====================================================================

-- QUESTÃO 2: RANKING MENSAL DE VENDEDORES
-- Objetivo: Criar um pódio de vendas para cada mês comercial, reiniciando o 
-- ranking a cada período.

WITH receita_vendedor_mes AS (
    -- Etapa 1: Consolidamos o faturamento de cada vendedor por mês usando GROUP BY
    SELECT 
        TRUNC(v.dt_venda, 'MM') AS mes_ref, 
        ven.nome AS vendedor, 
        SUM(v.valor_liquido) AS receita
    FROM tb_venda v
    JOIN tb_vendedor ven ON ven.id_vendedor = v.id_vendedor
    WHERE v.status = 'FECHADA'
    GROUP BY TRUNC(v.dt_venda, 'MM'), ven.nome
)
-- Etapa 2: Aplicamos a função analítica sobre os valores consolidados
SELECT 
    mes_ref, 
    vendedor, 
    receita,
    -- DENSE_RANK() não pula posições em caso de empate (ex: 1º, 2º, 2º, 3º...)
    -- PARTITION BY mes_ref garante um pódio fechado e isolado para cada mês
    DENSE_RANK() OVER (
        PARTITION BY mes_ref 
        ORDER BY receita DESC
    ) AS posicao_ranking
FROM receita_vendedor_mes
ORDER BY mes_ref, posicao_ranking;


-- QUESTÃO 3: OS 2 PRODUTOS MAIS VENDIDOS POR CATEGORIA
-- Objetivo: Identificar os principais geradores de volume por categoria de produto.

WITH vendas_produto AS (
    -- Etapa 1: Soma a quantidade total vendida de cada produto/categoria
    SELECT 
        c.nome AS categoria, 
        p.nome AS produto, 
        SUM(i.quantidade) AS total_vendido
    FROM tb_produto p
    JOIN tb_categoria c ON c.id_categoria = p.id_categoria
    JOIN tb_venda_item i ON p.id_produto = i.id_produto
    JOIN tb_venda v ON v.id_venda = i.id_venda
    WHERE v.status = 'FECHADA'
    GROUP BY c.nome, p.nome
),
ranking_produtos AS (
    -- Etapa 2: Cria o ranking analítico por categoria
    SELECT 
        categoria, 
        produto, 
        total_vendido,
        DENSE_RANK() OVER (
            PARTITION BY categoria 
            ORDER BY total_vendido DESC
        ) AS posicao
    FROM vendas_produto
)
-- Etapa 3: Filtramos o resultado final (Top 2)
-- Nota: Como o banco processa funções analíticas por último, o filtro do ranking
-- precisa obrigatoriamente ser feito em uma etapa externa (fora da cláusula OVER).
SELECT categoria, produto, total_vendido, posicao
FROM ranking_produtos
WHERE posicao <= 2
ORDER BY categoria, posicao;


-- =====================================================================
-- PARTE 3: INDICADORES E MATEMÁTICA ANALÍTICA (SUM & AVG OVER)
-- =====================================================================

-- QUESTÃO 4: PARTICIPAÇÃO NO FATURAMENTO (MARKET SHARE INTERNO)
-- Objetivo: Descobrir o peso de cada vendedor em relação ao faturamento total da empresa.

WITH receita_vendedor AS (
    SELECT 
        ven.nome AS vendedor, 
        SUM(v.valor_liquido) AS receita
    FROM tb_vendedor ven
    JOIN tb_venda v ON v.id_vendedor = ven.id_vendedor
    WHERE v.status = 'FECHADA'
    GROUP BY ven.nome
)
SELECT 
    vendedor, 
    receita, 
    -- SUM(receita) OVER () calcula o faturamento total global sem precisar agrupar.
    -- Isso permite realizar a divisão de cada linha pelo todo na mesma etapa.
    ROUND(receita / SUM(receita) OVER () * 100, 2) AS percentual_faturamento
FROM receita_vendedor
ORDER BY percentual_faturamento DESC;


-- QUESTÃO 5: TERMÔMETRO DE VENDAS (ACIMA OU ABAIXO DA MÉDIA?)
-- Objetivo: Identificar instantaneamente quais vendas performaram acima ou abaixo
-- do ticket médio corporativo, mantendo a listagem individualizada.

SELECT 
    id_venda, 
    valor_liquido, 
    -- AVG(valor_liquido) OVER () calcula a média de todas as linhas de forma transparente
    ROUND(AVG(valor_liquido) OVER (), 2) AS media_geral,
    -- Calculamos a diferença de desvio da linha atual em relação a essa média global
    ROUND(valor_liquido - AVG(valor_liquido) OVER (), 2) AS diferenca_media
FROM tb_venda
WHERE status = 'FECHADA'
ORDER BY valor_liquido DESC;
