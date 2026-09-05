-- =====================================================================
-- GABARITO COMENTADO - EXERCÍCIOS DA UNIDADE 3
-- MODELAGEM FÍSICA E QUALIDADE DE DADOS
-- Disciplina: Programação de Scripts de Banco de Dados (Oracle Database 23ai)
-- =====================================================================

-- ---------------------------------------------------------------------
-- PARTE 1: TESTANDO A RESILIÊNCIA (O PRINCÍPIO DE "FALHAR CEDO")
-- ---------------------------------------------------------------------

-- Questão 1: Violação de Chave Estrangeira (FK)
-- Tentativa de registrar uma venda com id_cliente inexistente (ex: 9999)
-- Retorno esperado do Oracle: 
-- ORA-02291: integrity constraint (FK_TB_VENDA_CLIENTE) violated - parent key not found
INSERT INTO tb_venda (id_cliente, id_vendedor, dt_venda, status, canal) 
VALUES (9999, 1, SYSDATE, 'ABERTA', 'LOJA');

/* 
   Comentário do Professor:
   Este comando falha porque o banco de dados exige integridade referencial. 
   A constraint 'fk_tb_venda_cliente' impede que uma venda seja registrada sem um 
   cliente real previamente cadastrado na tabela 'tb_cliente'. Isso evita "vendas órfãs" 
   que distorceriam as métricas comerciais e os relatórios de CRM.
*/


-- Questão 2: Violação de Domínio (CHECK Constraint)
-- Tentativa de atualizar o status de uma venda para o valor inválido 'PENDENTE'
-- Retorno esperado do Oracle:
-- ORA-02290: check constraint (CK_TB_VENDA_STATUS) violated
UPDATE tb_venda 
SET status = 'PENDENTE' 
WHERE id_venda = 1;

/* 
   Comentário do Professor:
   A constraint 'ck_tb_venda_status' restringe os valores aceitáveis nesta coluna 
   estritamente para 'ABERTA', 'FECHADA' ou 'CANCELADA'. Validar isso diretamente na 
   estrutura física do banco de dados (e não apenas na interface do usuário) garante 
   que, se um bug no aplicativo ou uma integração externa tentar forçar um status inválido, 
   o banco rejeitará, assegurando a integridade e qualidade da informação.
*/


-- Questão 3: Impedindo Preços Absurdos
-- Tentativa de cadastrar produto com preço unitário negativo
-- Retorno esperado do Oracle:
-- ORA-02290: check constraint (CK_TB_PRODUTO_PRECO) violated
INSERT INTO tb_produto (id_categoria, sku, nome, preco_unit) 
VALUES (1, 'SKU-TEMP-01', 'Produto Teste Negativo', -15.00);

/* 
   Comentário do Professor:
   A constraint de validação 'ck_tb_produto_preco' (preco_unit > 0) bloqueia essa 
   inserção. Essa regra impede erros de digitação ou fraudes que poderiam lançar valores 
   negativos de preços no inventário, o que distorceria completamente os dashboards de receita.
*/


-- ---------------------------------------------------------------------
-- PARTE 2: EVOLUINDO A MODELAGEM FÍSICA (DDL)
-- ---------------------------------------------------------------------

-- Questão 4: Limite de Desconto de Itens (CHECK)
-- Adicionar constraint que garante que o desconto_item não passe de 50% do valor do preco_unit
ALTER TABLE tb_venda_item 
ADD CONSTRAINT ck_tb_item_desconto_max 
CHECK (desconto_item <= (preco_unit * 0.50));

/* 
   Comentário do Professor:
   No Oracle, as constraints CHECK podem comparar valores de diferentes colunas da mesma 
   linha. Aqui, garantimos que nenhum vendedor consiga aplicar um desconto unitário 
   superior a 50% do valor unitário do produto. Qualquer tentativa de burlar essa regra será 
   bloqueada na hora da escrita (INSERT/UPDATE).
*/


-- Questão 5: Garantia de Unicidade de Contato (UNIQUE)
-- Garantir que não existam dois clientes com o mesmo número de telefone
ALTER TABLE tb_cliente 
ADD CONSTRAINT uq_tb_cliente_telefone UNIQUE (telefone);

/* 
   Comentário do Professor:
   A restrição UNIQUE gera um índice exclusivo sob o capô para garantir que nenhum 
   telefone se repita na base de clientes. No entanto, é importante lembrar que 
   valores nulos (NULL) são ignorados pela restrição UNIQUE no Oracle, ou seja, múltiplos 
   clientes podem ficar sem telefone cadastrado, mas se cadastrarem, o valor deve ser único.
*/


-- ---------------------------------------------------------------------
-- PARTE 3: COMPORTAMENTO DE EXCLUSÃO (CASCADE VS. SOFT DELETE)
-- ---------------------------------------------------------------------

-- Questão 6: Exclusão em Cascata (ON DELETE CASCADE)
-- Deletar a venda e observar o comportamento dos itens associados
DELETE FROM tb_venda WHERE id_venda = 1;

-- Consulta para verificar se os itens órfãos também foram limpos automaticamente
SELECT * FROM tb_venda_item WHERE id_venda = 1;

/* 
   Comentário do Professor:
   A chave estrangeira 'fk_item_venda' foi configurada com o comportamento 'ON DELETE CASCADE'. 
   Isso indica que, ao removermos um registro pai (a Venda), o Oracle varre a tabela filho 
   (Itens de Venda) e apaga automaticamente todos os registros dependentes. 
   Isso automatiza a limpeza física e protege o modelo contra a permanência de dados inconsistentes.
*/


-- Questão 7: Exclusão Lógica (Soft Delete)
-- Desativação lógica de um vendedor para manter a integridade histórica de vendas passadas
UPDATE tb_vendedor 
SET ativo = 'N' 
WHERE id_vendedor = 1;

/* 
   Comentário do Professor:
   A exclusão física (DELETE) de cadastros mestres como Clientes, Vendedores e Produtos 
   é uma prática perigosa no mercado comercial. Se deletássemos o Vendedor ID 1, todas as 
   vendas históricas associadas a ele teriam que ser deletadas ou perderiam a referência. 
   O 'Soft Delete' (atualizar a coluna ativo para 'N') inativa o cadastro para novos lançamentos 
   sem apagar o histórico de faturamento da empresa.
*/
