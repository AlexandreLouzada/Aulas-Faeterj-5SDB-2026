-- =====================================================================
-- GABARITO COMENTADO: UNIDADE 1 - REVISÃO E SQL AVANÇADO
-- SISTEMA DE VENDAS E ANÁLISE COMERCIAL
-- Compatível com Oracle Database 23ai / Oracle APEX
-- =====================================================================

-- ---------------------------------------------------------------------
-- PARTE 1: REVISÃO DE CONSULTAS E AGRUPAMENTOS (JOIN E GROUP BY)
-- ---------------------------------------------------------------------

-- Questão 1: Desempenho de Vendas por Vendedor
-- Retornar o nome de cada vendedor e o valor total vendido por ele (vendas 'FECHADA'),
-- ordenando o resultado do maior para o menor faturamento.
SELECT 
    ven.nome AS vendedor, 
    SUM(v.valor_liquido) AS total_vendido
FROM tb_vendedor ven
JOIN tb_venda v ON ven.id_vendedor = v.id_vendedor
WHERE v.status = 'FECHADA'
GROUP BY ven.nome
ORDER BY total_vendido DESC;


-- Questão 2: Histórico de Compras do Cliente
-- Listar o nome dos clientes, a data da venda, o valor líquido e o status de todas as compras,
-- incluindo as vendas canceladas.
SELECT 
    c.nome AS cliente, 
    v.dt_venda, 
    v.valor_liquido,
    v.status
FROM tb_cliente c
JOIN tb_venda v ON c.id_cliente = v.id_cliente
ORDER BY c.nome, v.dt_venda;


-- Questão 3: O Melhor Cliente
-- Identificar o nome do cliente que possui o maior valor total acumulado em compras fechadas.
SELECT 
    c.nome AS cliente, 
    SUM(v.valor_liquido) AS faturamento_total
FROM tb_cliente c
JOIN tb_venda v ON c.id_cliente = v.id_cliente
WHERE v.status = 'FECHADA'
GROUP BY c.nome
ORDER BY faturamento_total DESC
FETCH FIRST 1 ROWS ONLY;


-- ---------------------------------------------------------------------
-- PARTE 2: SUBQUERIES, EXISTS, IN E CASE WHEN
-- ---------------------------------------------------------------------

-- Questão 4: Vendas Acima da Média (Subquery)
-- Listar o id_venda, a data e o valor líquido de todas as vendas cujo valor seja 
-- superior à média geral de todas as vendas com status 'FECHADA'.
SELECT 
    id_venda, 
    dt_venda, 
    valor_liquido 
FROM tb_venda 
WHERE status = 'FECHADA'
AND valor_liquido > (
    SELECT AVG(valor_liquido) 
    FROM tb_venda 
    WHERE status = 'FECHADA'
);


-- Questão 5: Estoque Encalhado (NOT EXISTS)
-- Liste o nome de todos os produtos ativos que nunca foram vendidos (não possuem 
-- registro correspondente na tabela de itens).
SELECT p.nome 
FROM tb_produto p 
WHERE p.ativo = 'S' 
AND NOT EXISTS (
    SELECT 1 
    FROM tb_venda_item i 
    WHERE i.id_produto = p.id_produto
);


-- Questão 6: Classificação Comercial de Clientes (CASE WHEN)
-- Listar o nome do cliente, seu faturamento total (vendas fechadas) e a classificação:
-- Ouro (> 10.000), Prata (entre 2.000 e 10.000) ou Bronze (< 2.000).
SELECT 
    c.nome,
    SUM(v.valor_liquido) AS faturamento,
    CASE 
        WHEN SUM(v.valor_liquido) > 10000 THEN 'Ouro'
        WHEN SUM(v.valor_liquido) >= 2000 THEN 'Prata'
        ELSE 'Bronze'
    END AS categoria_cliente
FROM tb_cliente c
JOIN tb_venda v ON c.id_cliente = v.id_cliente
WHERE v.status = 'FECHADA'
GROUP BY c.nome;


-- ---------------------------------------------------------------------
-- PARTE 3: ORGANIZAÇÃO DE CONSULTAS COMPLEXAS COM CTE (WITH)
-- ---------------------------------------------------------------------

-- Questão 7: Receita Mensal da Empresa
-- Criar uma CTE chamada receita_mensal que calcule o faturamento total das vendas fechadas
-- por mês, e exibir o resultado de forma cronológica.
WITH receita_mensal AS (
    SELECT 
        TRUNC(dt_venda, 'MM') AS mes_ref, 
        SUM(valor_liquido) AS receita
    FROM tb_venda
    WHERE status = 'FECHADA'
    GROUP BY TRUNC(dt_venda, 'MM')
)
SELECT mes_ref, receita 
FROM receita_mensal 
ORDER BY mes_ref;


-- Questão 8: Top 5 Produtos Mais Vendidos
-- Criar uma CTE para calcular a quantidade vendida de cada produto e exibir os 5 primeiros colocados.
WITH qtd_produto AS (
    SELECT 
        p.nome AS produto, 
        SUM(i.quantidade) AS total_vendido
    FROM tb_produto p
    JOIN tb_venda_item i ON p.id_produto = i.id_produto
    GROUP BY p.nome
)
SELECT produto, total_vendido 
FROM qtd_produto 
ORDER BY total_vendido DESC
FETCH FIRST 5 ROWS ONLY;
