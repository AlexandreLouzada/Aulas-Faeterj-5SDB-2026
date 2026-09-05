-- =====================================================================
-- GABARITO COMENTADO - UNIDADE 8: ORACLE APEX (INTEGRAÇÃO E DASHBOARDS)
-- Disciplina: Programação de Scripts de Banco de Dados
-- =====================================================================
-- Como o Oracle APEX é uma plataforma essencialmente visual e Low-Code,
-- este gabarito reúne:
-- 1. As consultas SQL/PLSQL que servem de "Back-end" para as páginas.
-- 2. Os scripts de LOV (List of Values) para os seletores amigáveis.
-- 3. As configurações de propriedades que devem ser validadas no Page Designer.
-- 4. A fundamentação das melhores práticas corporativas para cada etapa.
-- =====================================================================

-- ---------------------------------------------------------------------
-- PARTE 1: CRUDS E TELAS OPERACIONAIS (Interactive Grids)
-- ---------------------------------------------------------------------

-- [EXERCÍCIO 1] Interactive Grid de Clientes (tb_cliente)
-- -> Origem dos Dados (Source):
--    Tipo: Table / View
--    Tabela: TB_CLIENTE
--
-- -> Configuração da Coluna 'ATIVO' no Page Designer:
--    1. Selecionar a coluna ATIVO em "Columns".
--    2. No painel direito (Settings), alterar o "Type" de Text Field para: "Switch" (ou "Checkbox").
--    3. Configurar as propriedades do Switch:
--       - Use Component Default / Custom Values: Custom
--       - On Value (Checked): S
--       - Off Value (Unchecked): N
--
-- -> Fundamentação de Mercado:
--    Essa configuração traduz o dado técnico 'S'/'N' do banco de dados (que possui
--    uma constraint CHECK no dicionário) para um interruptor visual moderno e intuitivo (UX),
--    impedindo que o usuário digite valores inválidos como 'X' ou 'A' que seriam barrados pelo banco.


-- [EXERCÍCIO 2] Interactive Grid de Produtos (Uso da View Abstrata)
-- -> Origem dos Dados (Source):
--    Tipo: Table / View (ou SQL Query)
--    Nome: V_DIM_PRODUTO
--
-- -> SQL que roda por trás do componente (caso use SQL Query):
SELECT 
    id_produto,
    sku,
    produto_nome,
    preco_unit,
    ativo,
    id_categoria,
    categoria_nome
FROM v_dim_produto;
--
-- -> Configuração de Edição (DML):
--    Se o Interactive Grid for editável, certifique-se de configurar a propriedade
--    "Allowed Operations" para permitir apenas UPDATE, ou aponte a chave primária ID_PRODUTO
--    como "Primary Key" no APEX para que ele saiba como persistir os dados na tabela base.
--
-- -> Análise Crítica:
--    Por que o APEX deve consumir Views e não fazer múltiplos JOINs nas propriedades da tela?
--    1. Performance: O otimizador de consultas do Oracle consegue analisar melhor uma View compilada.
--    2. Segurança: Ocultamos a complexidade e colunas físicas que o usuário da tela não precisa ver.
--    3. Manutenibilidade: Se a relação de categorias mudar amanhã, o DBA corrige a View e todas
--       as telas conectadas se ajustam sozinhas, sem necessidade de recompilar páginas no APEX.


-- ---------------------------------------------------------------------
-- PARTE 2: FLUXOS COMPLEXOS E RELATÓRIOS INTERATIVOS
-- ---------------------------------------------------------------------

-- [EXERCÍCIO 3] Master-Detail (tb_venda -> tb_venda_item)
-- -> Configuração do Relacionamento no APEX Designer:
--    1. Criar uma região Master baseada na tabela TB_VENDA.
--    2. Criar uma região Detail do tipo Interactive Grid baseada em TB_VENDA_ITEM.
--    3. Na região Detail, configurar a propriedade "Master Region" apontando para a região Master.
--    4. Na coluna ID_VENDA do detalhe, definir a propriedade "Master Column" como ID_VENDA.
--
-- -> Consultas para as Listas de Valores (LOVs) Compartilhadas:
--    Para que o usuário veja nomes ao invés de códigos numéricos (IDs):

-- 3.1 LOV_CLIENTES (Tipo: SQL Query)
SELECT nome AS d, id_cliente AS r
FROM tb_cliente
WHERE ativo = 'S'
ORDER BY nome;
-- * d = Display Value (o que aparece na tela)
-- * r = Return Value (o ID gravado no banco de dados)

-- 3.2 LOV_VENDEDORES (Tipo: SQL Query)
SELECT nome AS d, id_vendedor AS r
FROM tb_vendedor
WHERE ativo = 'S'
ORDER BY nome;

-- 3.3 LOV_PRODUTOS (Tipo: SQL Query)
SELECT nome || ' (R$ ' || preco_unit || ')' AS d, id_produto AS r
FROM tb_produto
WHERE ativo = 'S'
ORDER BY nome;

-- -> Campos Read-Only (Somente Leitura) na Venda:
--    As colunas VALOR_BRUTO, DESCONTO_TOTAL e VALOR_LIQUIDO da tabela principal (Master)
--    devem ser definidas como: "Read Only" -> "Always".
--    Isso garante que o usuário não manipule esses campos manualmente. O banco de dados
--    se encarregará de atualizá-los via Procedures de faturamento ou lógica interna.


-- [EXERCÍCIO 4] Relatório Gerencial (Interactive Report)
-- -> Origem dos Dados (Source):
--    Tipo: Table / View
--    Nome: V_VENDAS_RESUMO
--
-- -> SQL subjacente:
SELECT id_venda, dt_venda, status, canal, cliente_nome, vendedor, valor_liquido
FROM v_vendas_resumo;
--
-- -> Atividades Práticas no Menu do Usuário do APEX:
--    Os alunos devem ser instruídos a simular ações que um gerente comercial faria:
--    1. Filtro: Ir em "Actions" -> "Filter" e selecionar CANAL = 'APP'.
--    2. Agrupamento: Ir em "Actions" -> "Format" -> "Group By" e agrupar por STATUS somando o VALOR_LIQUIDO.
--    3. Download: Ir em "Actions" -> "Download" para exportar em formato XLS ou PDF.


-- ---------------------------------------------------------------------
-- PARTE 3: ORACLE APEX ANALÍTICO (Dashboards e KPIs)
-- ---------------------------------------------------------------------

-- [EXERCÍCIO 5] Indicadores-Chave (Região tipo Cards)
-- -> Origem dos Dados (Source):
--    Tipo: SQL Query
--    Consulta:
SELECT 
    'Faturamento de Hoje' AS kpi_titulo,
    receita_hoje          AS kpi_valor,
    'fa-money'            AS kpi_icone,
    'Vendas fechadas na data atual' AS kpi_sub
FROM v_kpi_vendas
UNION ALL
SELECT 
    'Acumulado (7 dias)'  AS kpi_titulo,
    receita_7_dias        AS kpi_valor,
    'fa-line-chart'       AS kpi_icone,
    'Receita bruta acumulada' AS kpi_sub
FROM v_kpi_vendas
UNION ALL
SELECT 
    'Faturamento do Mês'  AS kpi_titulo,
    receita_mes_atual     AS kpi_valor,
    'fa-calendar'         AS kpi_icone,
    'Faturamento mensal consolidado' AS kpi_sub
FROM v_kpi_vendas
UNION ALL
SELECT 
    'Volume de Vendas'    AS kpi_titulo,
    qtd_vendas_mes_atual  AS kpi_valor,
    'fa-shopping-cart'    AS kpi_icone,
    'Total de pedidos fechados no mês' AS kpi_sub
FROM v_kpi_vendas;

-- -> Configurações visuais dos Cards no APEX:
--    - Title: KPI_TITULO
--    - Body: KPI_SUB
--    - Badge (ou Primary Value): KPI_VALOR (Configurar máscara para R$999G999G990D00)
--    - Icon: KPI_ICONE


-- [EXERCÍCIO 6] Gráficos de Análise Visual (Charts Region)

-- 6.1 Gráfico de Linha (Série Temporal de Vendas)
-- -> Region Type: Chart
-- -> Attributes -> Type: Line
-- -> Series -> Source: SQL Query
SELECT dia, receita
FROM v_serie_receita_dia_30d
ORDER BY dia ASC;
-- -> Column Mapping:
--    - Label: DIA (Eixo X)
--    - Value: RECEITA (Eixo Y)

-- 6.2 Gráfico de Barras (Receita por Categoria no Mês Atual)
-- -> Region Type: Chart
-- -> Attributes -> Type: Bar
-- -> Series -> Source: SQL Query
SELECT categoria, receita_total
FROM v_vendas_por_categoria
WHERE mes_ref = TRUNC(SYSDATE, 'MM')
ORDER BY receita_total DESC;
-- -> Column Mapping:
--    - Label: CATEGORIA (Eixo X)
--    - Value: RECEITA_TOTAL (Eixo Y)

-- =====================================================================
-- FIM DO SCRIPT DE GABARITO (UNIDADE 8)
-- =====================================================================
