-- =====================================================================
-- GABARITO COMENTADO: UNIDADE 6 – TRIGGERS E AUDITORIA
-- DISCIPLINA: PROGRAMAÇÃO DE SCRIPTS DE BANCO DE DADOS
-- =====================================================================
-- Este script contém as soluções oficiais para os exercícios práticos
-- da Unidade 6, focada no uso de Triggers (Gatilhos) no Oracle Database.
-- =====================================================================

-- ---------------------------------------------------------------------
-- PARTE 1: AUDITORIA E RASTREABILIDADE (AFTER TRIGGER)
-- ---------------------------------------------------------------------

-- [Exercício 1] Criação da Trigger de Auditoria de Vendas (trg_aud_tb_venda)
-- Objetivo: Gravar de forma automatizada e invisível o histórico de ações
-- na tabela tb_venda para fins de segurança e rastreabilidade (logs).
-- Usamos AFTER porque não queremos bloquear a ação de escrita principal.

CREATE OR REPLACE TRIGGER trg_aud_tb_venda
AFTER INSERT OR UPDATE OR DELETE ON tb_venda
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO tb_auditoria_venda (
            id_venda, 
            operacao, 
            usuario_bd, 
            detalhes
        ) VALUES (
            :NEW.id_venda, 
            'INSERT', 
            USER, 
            'Venda criada com status inicial: ' || :NEW.status || ' no canal ' || :NEW.canal
        );
        
    ELSIF UPDATING THEN
        INSERT INTO tb_auditoria_venda (
            id_venda, 
            operacao, 
            usuario_bd, 
            detalhes
        ) VALUES (
            :NEW.id_venda, 
            'UPDATE', 
            USER, 
            'Alteração de status: ' || :OLD.status || ' -> ' || :NEW.status || 
            ' | Valor Líquido: R$ ' || :OLD.valor_liquido || ' -> R$ ' || :NEW.valor_liquido
        );
        
    ELSIF DELETING THEN
        INSERT INTO tb_auditoria_venda (
            id_venda, 
            operacao, 
            usuario_bd, 
            detalhes
        ) VALUES (
            :OLD.id_venda, 
            'DELETE', 
            USER, 
            'Venda removida fisicamente do banco de dados.'
        );
    END IF;
END;
/

-- [Exercício 2] Teste Prático da Trigger de Auditoria
-- Objetivo: Executar uma alteração na tabela tb_venda e verificar se
-- a trigger gravou o log de forma oculta e automática.

-- Passo A: Atualizar o status de uma venda para 'FECHADA' (por exemplo, ID 1)
UPDATE tb_venda 
SET status = 'FECHADA' 
WHERE id_venda = 1;

-- Passo B: Consultar a tabela de auditoria para validar o gatilho
SELECT id_auditoria, id_venda, dt_evento, operacao, usuario_bd, detalhes
FROM tb_auditoria_venda
ORDER BY dt_evento DESC;


-- ---------------------------------------------------------------------
-- PARTE 2: VALIDAÇÃO E BLOQUEIO PROATIVO (BEFORE TRIGGER)
-- ---------------------------------------------------------------------

-- [Exercício 3] Criação da Trigger de Bloqueio (trg_valida_venda_cancelada)
-- Objetivo: Garantir a regra de negócio inviolável de que uma venda que já
-- foi cancelada nunca mais possa sofrer nenhuma alteração em seus dados.
-- Usamos BEFORE para barrar a transação antes do salvamento físico (commit).

CREATE OR REPLACE TRIGGER trg_valida_venda_cancelada
BEFORE UPDATE ON tb_venda
FOR EACH ROW
BEGIN
    -- Se o status antes da tentativa de atualização já era 'CANCELADA'
    IF :OLD.status = 'CANCELADA' THEN
        RAISE_APPLICATION_ERROR(
            -20005, 
            'Erro de Integridade Comercial: Uma venda já CANCELADA não pode sofrer alterações!'
        );
    END IF;
END;
/

-- Exemplo de Teste de Bloqueio (Execução opcional):
-- Se tentarmos alterar o canal ou valor de uma venda cancelada, o Oracle bloqueará:
-- UPDATE tb_venda SET canal = 'LOJA' WHERE status = 'CANCELADA' AND ROWNUM = 1;
-- Resultado esperado: ORA-20005: Erro de Integridade Comercial: Uma venda já CANCELADA não pode sofrer alterações!


-- ---------------------------------------------------------------------
-- PARTE 3: ANÁLISE CRÍTICA (DISCUSSÃO PROFISSIONAL)
-- ---------------------------------------------------------------------

/*
[Exercício 4] O Perigo do Recálculo Automático por Triggers (Discussão)

Proposta: Criar uma trigger que a cada INSERT de item (tb_venda_item) 
faça um UPDATE automático na tabela pai (tb_venda) recalculando o valor total.

Por que essa automação, embora pareça cômoda, é considerada uma má prática?

1. IMPACTO DE PERFORMANCE (Processamento Linha a Linha):
   Triggers do tipo "FOR EACH ROW" executam uma vez para CADA linha modificada. 
   Se o sistema realizar um insert de carga em lote com 5.000 itens de uma só vez,
   a trigger rodará 5.000 vezes individuais, disparando 5.000 consultas pesadas 
   de agregação (SUM) e 5.000 comandos de UPDATE na tabela pai. Isso gera um gargalo
   de concorrência e trava o banco de dados (Row Lock Contention).

2. ERRO DE TABELA MUTANTE (Mutating Table Error):
   No Oracle, se tentarmos ler ou modificar de dentro de uma trigger de linha
   a própria tabela que a disparou ou tabelas fortemente relacionadas em cascata, 
   o banco lança a famosa exceção "ORA-04091: table is mutating". Trata-se de uma
   defesa do Oracle para evitar inconsistências de leitura fantasma.

3. REGRAS OCULTAS ("Efeito Caixa Preta"):
   Regras críticas de faturamento escondidas dentro de gatilhos reduzem drasticamente
   a rastreabilidade do sistema. Novos desenvolvedores podem passar dias tentando 
   entender por que um campo "muda de valor sozinho" ao salvar dados, dificultando
   a depuração e a manutenção do software.

SOLUÇÃO RECOMENDADA NO MERCADO:
   Em vez de utilizar triggers, as operações de recálculo devem ser centralizadas e
   encapsuladas em Procedures do banco (como a 'pr_registrar_venda' da Unidade 8)
   ou resolvidas de forma assíncrona/via backend da aplicação de forma explícita.
*/
