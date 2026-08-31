-- =====================================================================
-- SCRIPT DA CAMADA LÓGICA E ANALÍTICA
-- SISTEMA DE VENDAS E ANÁLISE COMERCIAL (Views, Functions e Procedures)
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


-- ---------------------------------------------------------------------
-- 3. PL/SQL: ENCAPSULAMENTO DE REGRAS DE NEGÓCIO
-- ---------------------------------------------------------------------

-- 3.1 Function: Cálculo de Comissão (Regra: APP/SITE=3%, LOJA=2%, OUTROS=1%)
CREATE OR REPLACE FUNCTION fn_comissao_vendedor (
    p_id_venda IN NUMBER
) RETURN NUMBER
IS
    v_status tb_venda.status%TYPE;
    v_canal  tb_venda.canal%TYPE;
    v_valor  tb_venda.valor_liquido%TYPE;
    v_pct    NUMBER;
BEGIN
    -- Busca os dados da venda
    SELECT status, canal, valor_liquido
    INTO v_status, v_canal, v_valor
    FROM tb_venda
    WHERE id_venda = p_id_venda;

    -- Só paga comissão se a venda estiver FECHADA
    IF v_status <> 'FECHADA' THEN
        RETURN 0;
    END IF;

    -- Aplica a regra de negócio
    v_pct := CASE v_canal
                WHEN 'APP'  THEN 0.03
                WHEN 'SITE' THEN 0.03
                WHEN 'LOJA' THEN 0.02
                ELSE 0.01
             END;

    RETURN ROUND(v_valor * v_pct, 2);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END;
/

-- 3.2 Procedure: Registro Centralizado de Vendas (Simulação em Lote)
CREATE OR REPLACE PROCEDURE pr_registrar_venda (
    p_id_cliente   IN NUMBER,
    p_id_vendedor  IN NUMBER,
    p_dt_venda     IN DATE,
    p_canal        IN VARCHAR2,
    p_ids_produto  IN SYS.ODCINUMBERLIST,
    p_qtds         IN SYS.ODCINUMBERLIST,
    p_descs_item   IN SYS.ODCINUMBERLIST,
    p_id_venda_out OUT NUMBER
)
IS
    v_id_venda NUMBER;
BEGIN
    -- Passo 1: Insere o cabeçalho da venda (com valores zerados)
    INSERT INTO tb_venda (id_cliente, id_vendedor, dt_venda, status, canal, valor_bruto, desconto_total, valor_liquido)
    VALUES (p_id_cliente, p_id_vendedor, NVL(p_dt_venda, SYSDATE), 'ABERTA', p_canal, 0, 0, 0)
    RETURNING id_venda INTO v_id_venda;

    -- Passo 2: Insere todos os itens da venda via Loop
    FOR i IN 1 .. p_ids_produto.COUNT LOOP
        DECLARE
            v_preco tb_produto.preco_unit%TYPE;
        BEGIN
            -- Busca o preço atualizado do produto
            SELECT preco_unit INTO v_preco FROM tb_produto WHERE id_produto = p_ids_produto(i);

            -- Registra o item
            INSERT INTO tb_venda_item (id_venda, id_produto, quantidade, preco_unit, desconto_item, valor_total)
            VALUES (
                v_id_venda, 
                p_ids_produto(i), 
                p_qtds(i), 
                v_preco, 
                p_descs_item(i), 
                (p_qtds(i) * v_preco) - p_descs_item(i)
            );
        END;
    END LOOP;

    -- Passo 3: Atualiza a venda principal com o somatório dos itens (Recálculo total)
    UPDATE tb_venda
    SET valor_bruto    = (SELECT NVL(SUM(quantidade * preco_unit), 0) FROM tb_venda_item WHERE id_venda = v_id_venda),
        desconto_total = (SELECT NVL(SUM(desconto_item), 0) FROM tb_venda_item WHERE id_venda = v_id_venda),
        valor_liquido  = (SELECT NVL(SUM(valor_total), 0) FROM tb_venda_item WHERE id_venda = v_id_venda)
    WHERE id_venda = v_id_venda;

    -- Passo 4: Devolve o ID da venda recém-criada para a aplicação
    p_id_venda_out := v_id_venda;
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'Erro ao registrar venda: ' || SQLERRM);
END;
/