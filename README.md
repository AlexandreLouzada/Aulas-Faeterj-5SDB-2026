# Sistema de Vendas e Analise Comercial — SBD (Oracle 23ai)

Repositorio oficial da disciplina **Programacao de Scripts de Banco de Dados (5SBD)** — FAETERJ, semestre 2026-2.
Projeto de banco de dados relacional para um sistema de vendas e analise comercial, com scripts
organizados em camadas profissionais (DDL, Views, Seed, Regras de Negocio e Testes).

> Compatibilidade: **Oracle Database 23ai** / **Oracle APEX** (SQL Workshop).

---

## Estrutura do Repositorio

```
.
├── 01_ddl/                          # Camada DDL (Modelagem Fisica)
│   └── ddl_sistema_vendas.sql       # Cria 8 tabelas, constraints, indexes e identity columns
│
├── 02_views/                        # Camada de Abstração (Views)
│   └── views_sistema_vendas.sql     # Views operacionais (CRUDs/APEX) e analiticas (BI/Dashboard)
│
├── 03_seed/                         # Camada de Dados Iniciais (Seed)
│   └── seed_sistema_vendas.sql      # 5 categorias, 25 clientes, 6 vendedores, 20 produtos e 150+ vendas
│
├── 04_plsql/                        # Camada PL/SQL (Regras de Negocio)
│   └── plsql_regras_negocio.sql     # Function de comissao + Procedure de registro centralizado de vendas
│
└── 05_tests/                        # Gabaritos dos exercicios das Unidades 1 a 8
    ├── gabarito_unidade_1.sql       # Revisao de SQL e agrupamentos (JOIN/GROUP BY)
    ├── gabarito_unidade_2.sql       # Funcoes analiticas e clausula OVER
    ├── gabarito_unidade_3.sql       # Modelagem fisica e qualidade de dados
    ├── gabarito_unidade_4.sql       # Views como camada de abstracao, seguranca e reuso
    ├── gabarito_unidade_5.sql       # Introducao ao PL/SQL (blocos, %TYPE, condicionais e loops)
    ├── gabarito_unidade_6.sql       # Triggers e auditoria
    ├── gabarito_unidade_7.sql       # Scripts em projetos (organizacao, versionamento, smoke tests)
    └── gabarito_unidade_8.sql       # Oracle APEX (integracao e dashboards)
```

---

## Modelo de Dados (8 Tabelas)

| Tabela | Descricao |
| :--- | :--- |
| `tb_categoria` | Categorias dos produtos (`Tecnologia`, `Eletrodomesticos`, `Moveis`, etc.) |
| `tb_cliente` | Clientes com CPF unico, email unico e flag de ativo |
| `tb_vendedor` | Vendedores da equipe comercial |
| `tb_produto` | Produtos com SKU unico, preco unitario e FK para categoria |
| `tb_venda` | Cabecalho das vendas (status `ABERTA/FECHADA/CANCELADA`, canal `APP/SITE/LOJA/TELEFONE`) |
| `tb_venda_item` | Itens da venda, com calculo de `valor_total` (qtd x preco - desconto) |
| `tb_auditoria_venda` | Trilha de auditoria para rastreabilidade (bonus) |
| `tb_calendario` | Dimensao calendario 2026 para analises de BI (bonus) |

---

## Instrucoes de Instalacao (Ordem de Execucao)

Execute os scripts **nesta ordem** no Worksheet do Oracle APEX (ou no SQL Developer):

| Ordem | Script | O que faz |
| :---: | :--- | :--- |
| 1 | `01_ddl/ddl_sistema_vendas.sql` | Cria as 8 tabelas com constraints e indexes |
| 2 | `03_seed/seed_sistema_vendas.sql` | Carrega os dados iniciais (categorias, clientes, vendedores, produtos, vendas) |
| 3 | `02_views/views_sistema_vendas.sql` | Cria as Views operacionais e analiticas |
| 4 | `04_plsql/plsql_regras_negocio.sql` | Compila a Function de comissao e a Procedure de registro de vendas |

Observacoes:

- O script DDL possui uma secao opcional de limpeza (`DROP TABLE ...`) no inicio. Ele pode ser executado
  para resetar o schema a cada nova execucao de implantacao.
- O seed usa `ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD'` e define as datas com `TO_DATE(...)`.
- Ao recarregar a base, execute **sempre** o DDL antes do seed para evitar conflito de identidades.

### Testando a camada PL/SQL

```sql
-- 1. Chamada da Function de comissao dentro de um SELECT
SELECT v.id_venda, v.valor_liquido,
       fn_comissao_vendedor(v.id_venda) AS comissao
FROM tb_venda v
WHERE v.status = 'FECHADA';

-- 2. Chamada da Procedure com registro em lote
DECLARE
    v_id_venda_out NUMBER;
BEGIN
    pr_registrar_venda(
        p_id_cliente  => 1,
        p_id_vendedor => 1,
        p_dt_venda    => TRUNC(SYSDATE),
        p_canal       => 'LOJA',
        p_ids_produto => SYS.ODCINUMBERLIST(1, 2),
        p_qtds        => SYS.ODCINUMBERLIST(1, 2),
        p_descs_item  => SYS.ODCINUMBERLIST(0, 0),
        p_id_venda_out => v_id_venda_out
    );
    DBMS_OUTPUT.PUT_LINE('Venda criada com ID: ' || v_id_venda_out);
END;
/
```

---

## Exercicios e Gabaritos

Os arquivos na pasta `05_tests/` contem os gabaritos comentados das 8 unidades. Cada script pode ser
executado diretamente no banco, desde que a base esteja criada (DDL + Seed). Eles funcionam como
**smoke tests**: se retornarem os resultados esperados, o ambiente esta consistente.

---

## Autorias e Contexto

| Item | Detalhe |
| :--- | :--- |
| **Instituicao** | FAETERJ — Faculdade de Educacao Tecnologica do Estado do Rio de Janeiro |
| **Disciplina** | 5SBD — Programacao de Scripts de Banco de Dados (2026-2) |
| **Plataforma** | Oracle Database 23ai + Oracle APEX |
| **Tema do projeto** | Sistema de Vendas e Analise Comercial |