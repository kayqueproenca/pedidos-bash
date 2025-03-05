Esquema de tabelas:

Produto:
+-----------+-------------+------+-----+---------+-------+
| Field     | Type        | Null | Key | Default | Extra |
+-----------+-------------+------+-----+---------+-------+
| ID        | int(11)     | NO   | PRI | NULL    |       |
| NOME      | varchar(50) | NO   |     | NULL    |       |
| MARCA     | varchar(20) | NO   |     | NULL    |       |
| ESTOQUE   | int(11)     | NO   |     | NULL    |       |
| PRECO     | float       | NO   |     | NULL    |       |
| DESCRICAO | longtext    | YES  |     | 'N/D'   |       |
+-----------+-------------+------+-----+---------+-------+

Cliente:
+--------------+-------------+------+-----+----------+-------+
| Field        | Type        | Null | Key | Default  | Extra |
+--------------+-------------+------+-----+----------+-------+
| CPF          | bigint(20)  | NO   | PRI | NULL     |       |
| NOME_CLIENTE | varchar(50) | NO   |     | NULL     |       |
| QNT_COMPRAS  | int(11)     | YES  |     | 0        |       |
| FIDELIDADE   | varchar(30) | YES  |     | STANDARD |       |
| DESCONTO     | int(11)     | YES  |     | 1        |       |
+--------------+-------------+------+-----+----------+-------+
