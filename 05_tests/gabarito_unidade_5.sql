-- =====================================================================
-- GABARITO COMENTADO: UNIDADE 5 - INTRODUÇÃO AO PL/SQL
-- Disciplina: Script de Banco de Dados / Programação PL/SQL
-- Foco: Blocos Anônimos, Variáveis (%TYPE), Lógica Condicional e Loops
-- Compatível com Oracle Database 23ai / Oracle APEX
-- =====================================================================

-- Habilita a visualização de mensagens no console do SQL Developer / APEX SQL Commands
-- Nota: No Oracle APEX, certifique-se de que a aba "DBMS Output" esteja ativa.
SET SERVEROUTPUT ON;

-- ---------------------------------------------------------------------
-- PARTE 1: O Bloco Básico, Variáveis e a Regra do SELECT INTO
-- ---------------------------------------------------------------------

-- 1. Cálculo de Faturamento Total (SELECT INTO com %TYPE)
-- Objetivo: Buscar o faturamento total acumulado e armazenar em uma variável ancorada.
DECLARE
    -- %TYPE ancora a variável ao tipo exato da coluna física do banco de dados,
    -- garantindo reuso, acoplamento fraco e prevenindo erros caso o tipo mude futuramente.
    v_total_vendas tb_venda.valor_liquido%TYPE;
BEGIN
    SELECT SUM(valor_liquido)
    INTO v_total_vendas
    FROM tb_venda
    WHERE status = 'FECHADA';

    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('1. Faturamento Total (Vendas Fechadas): R$ ' || TO_CHAR(v_total_vendas, '999G999D99'));
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
END;
/

-- 2. Tratamento de Exceções (NO_DATA_FOUND)
-- Objetivo: Tratar de forma elegante a ausência de registros retornados pelo SELECT INTO.
-- Lembre-se: No PL/SQL, todo SELECT INTO deve retornar OBRIGATORIAMENTE uma e apenas uma linha.
DECLARE
    v_valor_liquido tb_venda.valor_liquido%TYPE;
    v_id_teste      tb_venda.id_venda%TYPE := 99999; -- ID inexistente para forçar o erro
BEGIN
    SELECT valor_liquido
    INTO v_valor_liquido
    FROM tb_venda
    WHERE id_venda = v_id_teste;

    DBMS_OUTPUT.PUT_LINE('O valor da venda ' || v_id_teste || ' é: R$ ' || v_valor_liquido);
EXCEPTION
    -- Captura a exceção clássica de quando nenhuma linha é retornada.
    -- Sem este tratamento, o Oracle interromperia a execução do programa de forma abrupta.
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('2. Aviso: Venda com ID ' || v_id_teste || ' não foi encontrada no sistema (NO_DATA_FOUND).');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('2. Erro inesperado: ' || SQLERRM);
END;
/


-- ---------------------------------------------------------------------
-- PARTE 2: Lógica Condicional (Regras de Negócio)
-- ---------------------------------------------------------------------

-- 3. Classificação de Venda por Faixa de Valor
-- Objetivo: Utilizar a estrutura IF/ELSIF/ELSE para categorizar o valor líquido recuperado.
DECLARE
    v_id_venda tb_venda.id_venda%TYPE := 1; -- ID de teste (Altere para testar com outras vendas)
    v_valor    tb_venda.valor_liquido%TYPE;
BEGIN
    -- Busca o valor líquido da venda especificada
    SELECT valor_liquido 
    INTO v_valor 
    FROM tb_venda 
    WHERE id_venda = v_id_venda;

    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('3. Classificação da Venda ID: ' || v_id_venda);
    DBMS_OUTPUT.PUT_LINE('   Valor Líquido: R$ ' || TO_CHAR(v_valor, '999G999D99'));
    
    -- Lógica de tomada de decisão com base nas faixas de valor definidas
    IF v_valor < 500 THEN
        DBMS_OUTPUT.PUT_LINE('   Classificação Comercial: Venda BAIXA');
    ELSIF v_valor >= 500 AND v_valor <= 2000 THEN
        DBMS_OUTPUT.PUT_LINE('   Classificação Comercial: Venda MÉDIA');
    ELSE
        DBMS_OUTPUT.PUT_LINE('   Classificação Comercial: Venda ALTA');
    END IF;
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('3. Erro: Venda com ID ' || v_id_venda || ' não existe no banco de dados.');
END;
/


-- ---------------------------------------------------------------------
-- PARTE 3: Estruturas de Repetição (Processamento em Lote)
-- ---------------------------------------------------------------------

-- 4. Listagem de Clientes Ativos (FOR LOOP com Cursor Implícito)
-- Objetivo: Iterar sobre múltiplos registros sem precisar gerenciar a abertura e fechamento de cursores manualmente.
BEGIN
    DBMS_OUTPUT.PUT_LINE('4. Listagem de Clientes Ativos (FOR LOOP):');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    
    -- O Oracle abre o cursor, faz o fetch e fecha automaticamente o cursor ao término do loop.
    -- A variável de controle 'r_cliente' é declarada implicitamente com as colunas retornadas pelo SELECT.
    FOR r_cliente IN (
        SELECT nome, email 
        FROM tb_cliente 
        WHERE ativo = 'S'
        ORDER BY nome
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('   Cliente: ' || RPAD(r_cliente.nome, 20) || ' | E-mail: ' || r_cliente.email);
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
END;
/

-- 5. Simulação de Processamento (LOOP Básico com controle de saída EXIT WHEN)
-- Objetivo: Executar ações iterativas com controle manual de incremento e encerramento.
DECLARE
    v_contador NUMBER := 1;
BEGIN
    DBMS_OUTPUT.PUT_LINE('5. Execução do LOOP Básico:');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    
    LOOP
        DBMS_OUTPUT.PUT_LINE('   Processando iteração: ' || v_contador);
        
        -- Incremento manual (obrigatório no LOOP básico para evitar loop infinito)
        v_contador := v_contador + 1;
        
        -- Condição de saída imperativa que interrompe o processamento imediatamente
        EXIT WHEN v_contador > 5;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
END;
/
