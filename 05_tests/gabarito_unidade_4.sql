-- =====================================================================
-- SCRIPT DE GABARITO: EXERCÍCIOS DA UNIDADE 4
-- VIEWS COMO CAMADA DE ABSTRAÇÃO, SEGURANÇA E REUSO
-- Compatível com Oracle Database 23ai / Oracle APEX
-- =====================================================================

-- ---------------------------------------------------------------------
-- PARTE 1: ABSTRAÇÃO OPERACIONAL (Simplificando Telas e CRUDs)
-- ---------------------------------------------------------------------

-- Questão 1: View de Resumo de Vendas (V_VENDAS_RESUMO)
-- Objetivo: Centralizar os JOINs entre as tabelas de vendas, clientes e vendedores.
CREATE OR REPLACE VIEW v_vendas_resumo AS
SELECT 
    v.id_venda,
    v.dt_venda,
    v.status,
    v.canal,
    c.nome AS cliente,
    ven.nome AS vendedor,
    v.valor_liquido
FROM tb_venda v
JOIN tb_cliente c    ON c.id_cliente = v.id_cliente
JOIN tb_vendedor ven ON ven.id_vendedor = v.id_vendedor;

-- Comentário Didático:
-- Esta view encapsula a complexidade do modelo físico. As telas do Oracle APEX
-- ou relatórios de terceiros podem apenas fazer "SELECT * FROM v_vendas_resumo"
-- sem precisar conhecer as chaves estrangeiras ou repetir JOINs pesados.


-- ---------------------------------------------------------------------
-- PARTE 2: CAMADA DE SEGURANÇA E PRIVACIDADE (LGPD)
-- ---------------------------------------------------------------------

-- Questão 2: View de Cliente Público (V_CLIENTE_PUBLICO)
-- Objetivo: Restringir acesso a colunas sensíveis (como CPF e Telefone) e filtrar registros inativos.
CREATE OR REPLACE VIEW v_cliente_publico AS
SELECT 
    id_cliente,
    nome,
    email
FROM tb_cliente
WHERE ativo = 'S';

-- Comentário Didático:
-- Sob a ótica da LGPD (Lei Geral de Proteção de Dados), esta view serve como uma
-- barreira de segurança. Ao conceder acesso de leitura a esta view para sistemas externos,
-- garantimos que informações confidenciais fiquem inacessíveis e que apenas clientes ativos sejam exibidos.


-- ---------------------------------------------------------------------
-- PARTE 3: INTELIGÊNCIA DE NEGÓCIO (Views Analíticas para BI)
-- ---------------------------------------------------------------------

-- Questão 3: View de Receita por Categoria (V_VENDAS_POR_CATEGORIA)
-- Objetivo: Consolidar agrupamentos e cálculos de faturamento de forma pronta para gráficos.
CREATE OR REPLACE VIEW v_vendas_por_categoria AS
SELECT 
    TRUNC(v.dt_venda, 'MM') AS mes_ref,
    cat.nome AS categoria,
    SUM(i.valor_total) AS receita
FROM tb_venda v
JOIN tb_venda_item i  ON i.id_venda = v.id_venda
JOIN tb_produto p     ON p.id_produto = i.id_produto
JOIN tb_categoria cat ON cat.id_categoria = p.id_categoria
WHERE v.status = 'FECHADA'
GROUP BY TRUNC(v.dt_venda, 'MM'), cat.nome;

-- Comentário Didático:
-- Esta é uma view analítica clássica de BI. Ela processa dezenas de milhares de linhas
-- de itens de vendas e as resume de forma plana (flat). Ferramentas de dashboard, como
-- gráficos no Oracle APEX, consomem essa view de forma limpa e otimizada.


-- Questão 4: Consumindo a View Analítica
-- Objetivo: Escrever uma consulta simples para buscar categorias com receita > 5000 no mês atual.
SELECT 
    categoria, 
    receita 
FROM v_vendas_por_categoria
WHERE receita > 5000 
  AND mes_ref = TRUNC(SYSDATE, 'MM');

-- Comentário Didático:
-- Veja como a consulta externa se torna extremamente simples. Graças ao trabalho feito
-- pela View, não precisamos usar a cláusula HAVING ou reescrever todos os quatro JOINs.
-- O banco cuida da performance de forma otimizada.
