-- Como criar um novo PDB utilizando o SEED no Oracle:

-- Defini��es:

-- CDB (Container Database): Inclui o Root, o Seed e os PDBs.

-- SEED � um template predefinido que vem dentro do CDB 
-- e que serve para a cria��o de novos PDBs.

-- 1� Passo: Executar os comando abaixo no SQL*Plus. 
-- Para acess�-lo, digite no terminal:
sqlplus / as sysdba

-- 2� Passo: Verificar se o banco de dados � um CDB:
SELECT DBA FROM V$DATABASE;

CDB
---
YES

-- 3� Passo: Verificar na tabela V$PDBS os PDBs j� existentes:
COLUMN NAME FORMAT A15 
COLUMN RESTRICTED FORMAT A10 
COLUMN OPEN_TIME FORMAT A30 
SELECT NAME, OPEN_MODE, RESTRICTED, OPEN_TIME FROM V$PDBS;

NAME            OPEN_MODE  RESTRICTED OPEN_TIME
--------------- ---------- ---------- ------------------------------
PDB$SEED        READ ONLY  NO         08/07/22 09:34:24,969 -03:00
XEPDB1          READ WRITE NO         08/07/22 09:34:25,664 -03:00

-- 4� Passo: Verificar as tablespaces no ambiente de banco de dados:
SELECT * FROM V$TABLESPACE;

       TS# NAME            INC BIG FLA ENC     CON_ID
---------- --------------- --- --- --- --- ----------
         1 SYSAUX          YES NO  YES              1
         0 SYSTEM          YES NO  YES              1
         2 UNDOTBS1        YES NO  YES              1
         4 USERS           YES NO  YES              1
         3 TEMP            NO  NO  YES              1
         0 SYSTEM          YES NO  YES              2
         1 SYSAUX          YES NO  YES              2
         2 UNDOTBS1        YES NO  YES              2
         3 TEMP            NO  NO  YES              2
         0 SYSTEM          YES NO  YES              3
         1 SYSAUX          YES NO  YES              3
         2 UNDOTBS1        YES NO  YES              3
         3 TEMP            NO  NO  YES              3
         5 USERS           YES NO  YES              3

-- 5� Passo: Criar uma tablespace para o nosso pluggable database:
CREATE TABLESPACE TBS_SALESWEB 
    DATAFILE 'TBS_SALESWEB01.dbf' 
    SIZE 10M 
    AUTOEXTEND ON NEXT 10M 
    MAXSIZE 50M;

-- 6� Passo: Executar o 4� Passo para ver a nossa TBS_SALESWEB criada.

-- 7� Passo: Para criar um PDB utilizando o template SEED, obrigatoriamente rodamos os comandos
-- dentro do CDB Root (CDB$ROOT), sendo assim, verificamos o CDB$ROOT da seguinte forma:
SHOW CON_NAME;

CON_NAME
------------------------------
CDB$ROOT

-- 8� Passo: Executamos o comando "sho parameter create" para verificar se 
-- usamos o OMF (Oracle Manage Files) para setar o diret�rio onde ser�o 
-- criados todos os Pluggables Dabatases.
-- Caso a chave NAME db_create_file_dest estiver com o VALUE setado para algum 
-- path, significa que o Oracle sabe onde salvar os PDBs atrav�s do arquivo OMF. 
-- Contudo, caso o VALUE da db_create_file_dest esteja vazio devemos definir os 
-- par�metros para criar o PDB j� informando o path de onde ele ser� criado:
sho parameter create

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
create_bitmap_area_size              integer     8388608
create_stored_outlines               string
db_create_file_dest                  string
db_create_online_log_dest_1          string
db_create_online_log_dest_2          string
db_create_online_log_dest_3          string
db_create_online_log_dest_4          string
db_create_online_log_dest_5          string

-- 9� Passo: J� com a tablespace criada e feitas as devidas verifica��es, vamos 
-- criar nosso PDB (Pluggable Database), lembrando que temos que associar um 
-- usu�rio a este pluggable database. 

-- Caso estivermos usando Oracle Managed Files (OMF); para criar o PDB executamos o seguinte comando:
CREATE PLUGGABLE DATABASE SALESWEB_PDB ADMIN USER USR_SALESWEB IDENTIFIED BY Sal3sW3b
    DEFAULT TABLESPACE TBS_SALESWEB DATAFILE SIZE 1M AUTOEXTEND ON NEXT 1M;

-- Contudo, se n�o estivermos usando OMF; para criar o PDB devemos executar o comando abaixo:
CREATE PLUGGABLE DATABASE SALESWEB_PDB ADMIN USER USR_SALESWEB IDENTIFIED BY Sal3sW3b 
    FILE_NAME_CONVERT=('C:\Oracle\app\product\21c\oradata\XE\pdbseed','C:\Oracle\app\product\21c\oradata\XE\salesweb_pdb')
    DEFAULT TABLESPACE TBS_SALESWEB 
    DATAFILE 'C:\Oracle\app\product\21c\oradata\XE\salesweb_pdb\tbs_salesweb01.dbf' 
    SIZE 1M AUTOEXTEND ON NEXT 1M;

-- 10� Passo: Executar a query do 3� Passo para verificar os PDBs existentes.

-- 11� Passo: Ap�s a cria��o o novo banco (PDB) ele fica no estado de MOUNTED; 
-- e para disponibilizarmos esse banco para uso n�s executamos o seguinte comando:
ALTER PLUGGABLE DATABASE SALESWEB_PDB OPEN;

-- 12� Passo: Executar a query do 3� Passo para verificar se o nosso SALESWEB_PDB
-- j� est� com o OPEN_MODE setado como READ WRITE e pronto para uso.

-- 13� Passo: Mostrar os arquivos de dados para cada PDB em um CDB:
COLUMN PDB_ID FORMAT 999
COLUMN PDB_NAME FORMAT A8
COLUMN FILE_ID FORMAT 9999
COLUMN TABLESPACE_NAME FORMAT A10
COLUMN FILE_NAME FORMAT A45
SELECT p.PDB_ID, p.PDB_NAME, d.FILE_ID, d.TABLESPACE_NAME, d.FILE_NAME
    FROM DBA_PDBS p, CDB_DATA_FILES d
    WHERE p.PDB_ID = d.CON_ID
    ORDER BY p.PDB_ID;

-- 14� Passo: Para conseguir acessar o banco (PDB) que acabamos de criar, 
-- devemos mudar a sess�o da seguinte forma:
ALTER SESSION SET CONTAINER=SALESWEB_PDB;

-- 15� Passo: E para verificar qual banco estamos conectados, rodamos o comando:
SHOW CON_NAME

CON_NAME
------------------------------
SALESWEB_PDB

-- 16 Passo: No SQL Developer alternar do CDB CDB$ROOT para o PDB criado (SALESWEB_PDB):
ALTER SESSION SET container = SALESWEB_PDB;

-- 16� Passo: Para que o usu�rio criado (USR_SALESWEB) como ADMIN USER do PDB (SALESWEB_PDB) tenha 
-- permiss�o para manipular o banco de dados devemos setar as seguintes diretivas:
GRANT CREATE SESSION TO USR_SALESWEB;
GRANT CREATE TABLE TO USR_SALESWEB;

-- Com isso, podemos usar as migrations do EF com o usu�rio criado.