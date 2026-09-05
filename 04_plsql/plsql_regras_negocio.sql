-- =====================================================================
-- SCRIPT DA CAMADA PL/SQL: ENCAPSULAMENTO DE REGRAS DE NEGÓCIO
-- SISTEMA DE VENDAS E ANÁLISE COMERCIAL (Functions e Procedures)
-- Compatível com Oracle Database 23ai / Oracle APEX
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. FUNCTION: CÁLCULO DE COMISSÃO
-- Regra de Negócio: APP/SITE = 3% | LOJA = 2% | OUTROS = 1%
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- 2. PROCEDURE: REGISTRO CENTRALIZADO DE VENDAS (Simulação em Lote)
-- ---------------------------------------------------------------------
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
