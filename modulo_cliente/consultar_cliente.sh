#! /usr/bin/env bash

source ./variaveis_gerais

#set -x

consulta_nome_cpf(){
 while : ; do
  local COUNT=0
  local ALERTA=""
  local OPC=""
  local SAIR=""
  local CLIENTE=""
  while [ -z $CLIENTE ] ; do
   clear
   echo $DELIMITADOR
   echo -e $ALERTA
   read -p "Digite o CPF/NOME do cliente: " CLIENTE
   let COUNT++
   if [ $COUNT -gt 3 ] ; then
    ALERTA="${RED_BOLD}O CAMPO NÃO PODE FICAR EM BRANCO!!!${END_COLOR}"
   fi
  done
  if [[ "$CLIENTE" =~ [a-z|A-Z] ]] ; then
   clear
   echo $DELIMITADOR
   echo -e "Dados do cliente ${WHITE_BOLD}${CLIENTE}${END_COLOR}\n"
   mariadb -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "SELECT * FROM cliente WHERE NOME_CLIENTE REGEXP '^${CLIENTE}';" | awk -F "\t" 'NR!=1 {print "CPF: "$1"\nNOME: "$2"\nQUANTIDADE DE COMPRAS: "$3"\nFIDELIDADE: "$4"\nDESCONTO DISPONIVEL: "$5"%\n"}'
   QUANTIDADE=$(mariadb -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "SELECT COUNT(*) FROM cliente WHERE NOME_CLIENTE REGEXP '^${CLIENTE}';" | awk -F "\t" 'NR!=1{print $1}')
   echo -e "Total de clientes com o nome ${WHITE_BOLD}\"$CLIENTE\"${END_COLOR}: ${QUANTIDADE}"
  else
    clear
    QUANTIDADE=$(mariadb -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "SELECT COUNT(*) FROM cliente WHERE CPF = ${CLIENTE};" | awk -F "\t" 'NR!=1{print $1}')
    if [ $QUANTIDADE -gt 0 ] ; then
     echo $DELIMITADOR
     echo -e "Dados do CPF ${CLIENTE}\n"
     mariadb -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "SELECT * FROM cliente WHERE CPF = ${CLIENTE};" | awk -F "\t" 'NR!=1 {print "CPF: "$1"\nNOME: "$2"\nQUANTIDADE DE COMPRAS: "$3"\nFIDELIDADE: "$4"\nDESCONTO DISPONIVEL: "$5"%"}'
    else
     echo $DELIMITADOR
     echo -e "${RED_BOLD}Nenhum resultado para o CPF${END_COLOR} ${WHITE_BOLD}${CLIENTE}${END_COLOR}"
    fi
  fi
  echo "Consultar outro cliente?"
  select OPC in "SIM" "NÃO" ; do
   if [ $OPC = "SIM" ] ; then
    SAIR="sim"
    break
   else
    SAIR="não"
    break
   fi
  done
 
   if [ $SAIR = "não" ] ; then
    break
   else
    continue
   fi
 done
}

consulta_nome_cpf
