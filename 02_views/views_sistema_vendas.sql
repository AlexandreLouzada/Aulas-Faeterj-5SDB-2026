-- =====================================================================
-- SCRIPT DA CAMADA LÓGICA E ANALÍTICA
-- SISTEMA DE VENDAS E ANÁLISE COMERCIAL (Views)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. VIEWS OPERACIONAIS (Para CRUDs e Relatórios do APEX)
-- ---------------------------------------------------------------------

-- 1.1 View de Resumo de Vendas
CREATE OR REPLACE VIEW v_vendas_resumo AS
SELECT 
    v.id_venda,
    v.dt_venda,
    v.status,
    v.canal,
    c.nome AS cliente_nome,
    ven.nome AS vendedor,
    v.valor_liquido
FROM tb_venda v
JOIN tb_cliente c   ON c.id_cliente = v.id_cliente
JOIN tb_vendedor ven ON ven.id_vendedor = v.id_vendedor;

-- 1.2 View de Dimensão Produto (Facilita o CRUD no APEX)
CREATE OR REPLACE VIEW v_dim_produto AS
SELECT 
    p.id_produto,
    p.sku,
    p.nome AS produto_nome,
    p.preco_unit,
    p.ativo,
    c.id_categoria,
    c.nome AS categoria_nome
FROM tb_produto p
JOIN tb_categoria c ON c.id_categoria = p.id_categoria;

-- 1.3 View Flat de Vendas (Para o Interactive Report Completo)
CREATE OR REPLACE VIEW v_rel_vendas_flat AS
SELECT 
    v.id_venda,
    v.dt_venda,
    v.status,
    v.canal,
    c.nome AS cliente,
    ven.nome AS vendedor,
    p.sku,
    p.nome AS produto,
    cat.nome AS categoria,
    i.quantidade,
    i.preco_unit,
    i.desconto_item,
    i.valor_total
FROM tb_venda v
JOIN tb_cliente c     ON c.id_cliente = v.id_cliente
JOIN tb_vendedor ven  ON ven.id_vendedor = v.id_vendedor
JOIN tb_venda_item i  ON i.id_venda = v.id_venda
JOIN tb_produto p     ON p.id_produto = i.id_produto
JOIN tb_categoria cat ON cat.id_categoria = p.id_categoria;


-- ---------------------------------------------------------------------
-- 2. VIEWS ANALÍTICAS (Para o Dashboard da Diretoria)
-- ---------------------------------------------------------------------

-- 2.1 View de Vendas por Categoria (Gráfico de Barras)
CREATE OR REPLACE VIEW v_vendas_por_categoria AS
SELECT 
    TRUNC(v.dt_venda, 'MM') AS mes_ref,
    cat.nome AS categoria,
    SUM(i.quantidade) AS qtd_itens,
    SUM(i.valor_total) AS receita_total
FROM tb_venda v
JOIN tb_venda_item i  ON i.id_venda = v.id_venda
JOIN tb_produto p     ON p.id_produto = i.id_produto
JOIN tb_categoria cat ON cat.id_categoria = p.id_categoria
WHERE v.status = 'FECHADA'
GROUP BY TRUNC(v.dt_venda, 'MM'), cat.nome;

-- 2.2 Ranking Mensal de Vendedores (Com Funções Analíticas)
CREATE OR REPLACE VIEW v_rank_vendedores_mes AS
WITH receita_vendedor AS (
    SELECT 
        TRUNC(v.dt_venda, 'MM') AS mes_ref, 
        ven.nome AS vendedor, 
        SUM(v.valor_liquido) AS receita
    FROM tb_venda v
    JOIN tb_vendedor ven ON ven.id_vendedor = v.id_vendedor
    WHERE v.status = 'FECHADA'
    GROUP BY TRUNC(v.dt_venda, 'MM'), ven.nome
)
SELECT 
    mes_ref, 
    vendedor, 
    receita,
    DENSE_RANK() OVER (PARTITION BY mes_ref ORDER BY receita DESC) AS posicao
FROM receita_vendedor;

-- 2.3 Receita Diária dos Últimos 30 Dias (Gráfico de Série Temporal)
CREATE OR REPLACE VIEW v_serie_receita_dia_30d AS
SELECT 
    TRUNC(dt_venda) AS dia, 
    SUM(valor_liquido) AS receita
FROM tb_venda
WHERE status = 'FECHADA' AND dt_venda >= TRUNC(SYSDATE) - 30
GROUP BY TRUNC(dt_venda);

-- 2.4 Top 10 Clientes do Mês Atual (Tabela de Destaque)
CREATE OR REPLACE VIEW v_top_clientes_mes_atual AS
SELECT 
    c.nome AS cliente, 
    SUM(v.valor_liquido) AS receita
FROM tb_venda v
JOIN tb_cliente c ON c.id_cliente = v.id_cliente
WHERE v.status = 'FECHADA' AND TRUNC(v.dt_venda, 'MM') = TRUNC(SYSDATE, 'MM')
GROUP BY c.nome
ORDER BY receita DESC
FETCH FIRST 10 ROWS ONLY;

-- 2.5 KPIs Gerais do Sistema (Para os Cards)
CREATE OR REPLACE VIEW v_kpi_vendas AS
SELECT 
    (SELECT NVL(SUM(valor_liquido), 0) FROM tb_venda WHERE status = 'FECHADA' AND TRUNC(dt_venda) = TRUNC(SYSDATE)) AS receita_hoje,
    (SELECT NVL(SUM(valor_liquido), 0) FROM tb_venda WHERE status = 'FECHADA' AND dt_venda >= TRUNC(SYSDATE) - 7) AS receita_7_dias,
    (SELECT NVL(SUM(valor_liquido), 0) FROM tb_venda WHERE status = 'FECHADA' AND TRUNC(dt_venda, 'MM') = TRUNC(SYSDATE, 'MM')) AS receita_mes_atual,
    (SELECT COUNT(id_venda) FROM tb_venda WHERE status = 'FECHADA' AND TRUNC(dt_venda, 'MM') = TRUNC(SYSDATE, 'MM')) AS qtd_vendas_mes_atual
FROM dual;


