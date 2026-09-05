-- =====================================================================
-- GABARITO COMENTADO: UNIDADE 7 - SCRIPTS DE BANCO DE DADOS EM PROJETOS
-- TEMA: ORGANIZAÇÃO, VERSIONAMENTO, IMPLANTAÇÃO E SMOKE TESTS
-- =====================================================================

/*
---------------------------------------------------------------------
PARTE 1: ORGANIZAÇÃO E ORDEM DE EXECUÇÃO (Mapeamento de Pastas)
---------------------------------------------------------------------
Questão 1: Organizar os arquivos abaixo nas pastas profissionais
recomendadas, justificando a ordem exata de implantação.

Estrutura de Pastas e Ordem de Execução Recomendada:

1. Pasta: 01_ddl/
   Arquivo: tb_auditoria.sql
   Explicação: As tabelas físicas e a estrutura fundamental de restrições (constraints)
   do banco devem ser criadas primeiro, pois todos os outros objetos dependem delas.

2. Pasta: 02_views/
   Arquivo: v_vendas_resumo.sql
   Explicação: As views dependem diretamente da existência das tabelas físicas
   para serem compiladas sem erros de "tabela ou visão inexistente".

3. Pasta: 03_seed/
   Arquivo: carga_clientes.sql
   Explicação: A carga de dados inicial (Inserts) só pode ser feita quando a
   estrutura de tabelas, chaves primárias e estrangeiras já estiver totalmente pronta.

4. Pasta: 04_plsql/
   Arquivo: pr_cancelar_venda.sql
   Explicação: Procedures, Functions, Triggers e Packages devem ser os últimos objetos de
   código a compilar, pois frequentemente referenciam e validam tabelas, views e dados.

5. Pasta: 05_tests/
   Arquivo: 01_smoke_tests.sql
   Explicação: Os testes de fumaça (smoke tests) rodam ao final do processo de
   deploy para garantir que toda a migração foi bem-sucedida e o básico do sistema está online.
*/

-- ---------------------------------------------------------------------
-- PARTE 2: VERSIONAMENTO E IMPLANTAÇÃO (Migration e Rollback)
-- ---------------------------------------------------------------------

-- Questão 2: Script de Migração (V1.2_add_limite_credito.sql)
-- Objetivo: Adicionar a coluna limite_credito na tabela tb_cliente sem afetar dados antigos.

ALTER TABLE tb_cliente 
ADD limite_credito NUMBER(10,2) DEFAULT 0;

-- Comentário Técnico: O uso do "DEFAULT 0" garante que todos os registros existentes
-- na tabela já ganhem o valor zero em vez de NULL, o que previne erros em fórmulas e
-- relatórios da aplicação que consomem esse campo.


-- Questão 3: Script de Reversão (rollback_v1.2.sql)
-- Objetivo: Reverter completamente a alteração caso ocorra alguma falha em produção.

ALTER TABLE tb_cliente 
DROP COLUMN limite_credito;

-- Comentário Técnico: Todo script de migração precisa de um par de rollback correspondente.
-- Em caso de incidentes críticos, a remoção da coluna deve ser automatizada e livre de erros.


-- ---------------------------------------------------------------------
-- PARTE 3: GARANTIA DE QUALIDADE (01_smoke_tests_v1.2.sql)
-- ---------------------------------------------------------------------

-- Questão 4: Testes Pós-Implantação (Smoke Tests)
-- Objetivo: Validar de forma rápida se a implantação funcionou e se a base está íntegra.

-- Teste 1: Garantir que não houve perda ou corrupção de dados dos clientes ativos
SELECT COUNT(*) AS total_clientes_pos_deploy
FROM tb_cliente;

-- Teste 2: Consultar o dicionário de dados do Oracle para certificar-se da criação física da coluna
SELECT table_name, column_name, data_type, data_length, nullable
FROM user_tab_columns
WHERE table_name = 'TB_CLIENTE'
  AND column_name = 'LIMITE_CREDITO';

-- Comentário Técnico: O dicionário de dados do Oracle (user_tab_columns) é o local
-- de verdade incontestável. Este teste automatizado pode ser acoplado em esteiras de
-- CI/CD para validar o sucesso ou falha do deploy imediatamente.
