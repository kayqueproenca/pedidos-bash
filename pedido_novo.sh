#! /usr/bin/env bash
source ./variaveis_gerais

#set -x

cliente_registrado(){
 CLIENTE_PEDIDO=""
 local COUNT=0
 local LISTA_CLIENTE=()
 while : ; do
  clear
  echo $DELIMITADOR
  echo "Cliente registrado?"
  select OPC in "SIM" "NÃO" ; do
    if [ $REPLY -eq 1 ] ; then
     clear
     echo $DELIMITADOR
     read -p "Informe o NOME/CPF do cliente: " CLIENTE
     if [[ $CLIENTE =~ ^[a-z|A-Z] ]]; then
       mapfile -t LISTA_CLIENTE< <($CONEXAO -Be "SELECT NOME_CLIENTE FROM cliente WHERE NOME_CLIENTE REGEXP '^$CLIENTE'" | awk -F "\n" 'NR!=1 {print $1}')
       clear
       echo -e "Segue o resultado para o ${BLUE_BOLD}${CLIENTE^^}${END_COLOR}"
       select LISTA in "${LISTA_CLIENTE[@]}"; do
        CLIENTE=$LISTA
        break
       done
       clear
       echo $DELIMITADOR
       echo "Resultado da busca:"
       $CONEXAO -Be "SELECT CPF, NOME_CLIENTE, FIDELIDADE FROM cliente WHERE NOME_CLIENTE = '$CLIENTE';" | awk -F "\t" 'NR!=1 {print "CPF: "$1"\nNOME: "$2"\nFIDELIDADE: "$3}'
       CLIENTE_PEDIDO=$($CONEXAO -Be "Select CPF FROM cliente WHERE NOME_CLIENTE = '$CLIENTE';" | awk -F "\t" 'NR!=1 {print $1}')
       DESCONTO=$($CONEXAO -Be "Select DESCONTO FROM cliente WHERE CPF = $CLIENTE_PEDIDO;" | awk -F"\t" 'NR!=1 {print $1}')
       break
     else
       $CONEXAO -Be "SELECT CPF, NOME_CLIENTE, FIDELIDADE FROM cliente WHERE CPF = $CLIENTE;" | awk -F "\t" 'NR!=1 {print "CPF: "$1"\nNOME: "$2"\nFIDELIDADE: "$3}'
       CLIENTE_PEDIDO=$CLIENTE
       DESCONTO=$($CONEXAO -Be "Select DESCONTO FROM cliente WHERE CPF = $CLIENTE_PEDIDO;" | awk -F"\t" 'NR!=1 {print $1}')
       break
     fi
    else
     clear
     echo $DELIMITADOR
     echo "Compra com cliente não cadastrado"
     echo $DELIMITADOR
     CLIENTE_PEDIDO=11111111111
     break
    fi
  done

  echo -e "\nConfirma cliente?"
  select OPC in "SIM" "NÃO" "CANCELAR PEDIDO" ; do
   if [ $REPLY -eq 1 ] ; then
     SAIR="sim"
     break
   elif [ $REPLY -eq 2 ] ; then
     SAIR="nao"
     break
   else
    clear
    echo "Cancelando pedido..."
    CLIENTE_PEDIDO=""
    break
   fi
  done
  if [ "$SAIR" = "sim" ] ; then
    break
  else
   continue
  fi
 done
 lista_itens
}

mostrar_cliente(){
 if [ $1 -eq 11111111111 ] ; then
  echo -e "Compra com cliente não cadastrado\n${RED_BOLD}SEM DIREITO A DESCONTO FIDELIDADE${END_COLOR}"
 else
  $CONEXAO -Be "SELECT CPF, NOME_CLIENTE, FIDELIDADE FROM cliente WHERE CPF = $1;" | awk -F "\t" 'NR!=1 {print "CPF: "$1"\nNOME: "$2"\nFIDELIDADE: "$3}'
  echo -e "Desconto concedido ${BLUE_BOLD}${DESCONTO}%${END_COLOR}"
 fi
}

mostrar_produto(){
for (( i=0 ; i<= $COUNT_ITEM ; i++ )); do
 $CONEXAO -Be "SELECT NOME, PRECO FROM produto WHERE ID = ${LISTA_ITEM[$i]};" 2> /dev/null | awk -F"\t" 'NR!=1 {print $1 "  R$"$2}'
done
}

lista_itens(){
 LISTA_ITEM=()
 COUNT_ITEM=0
 QUANTIDADE_LISTA=()
 SUBTOTAL=0
 while : ; do
  while : ; do
   local ITEM=""
   local QUANTIDADE=""
   while [ -z $ITEM ] ; do
    clear
    echo $DELIMITADOR
    mostrar_cliente $CLIENTE_PEDIDO
    echo $DELIMITADOR
    echo -e "\nLista de itens:"
    mostrar_produto
    echo -e "\n
Subtotal: R\$ ${SUBTOTAL}"
    echo "Coloque o CÓDIGO/NOME do produto:"
    read -p "-> " ITEM
   done 
   if [[ $ITEM =~ ^[A-Z|a-z] ]] ; then
    readarray -t LISTA< <($CONEXAO -Be "SELECT DISTINCT NOME FROM produto WHERE NOME REGEXP '^$ITEM' ;" | awk -F "\n" 'NR!=1{print $1}')
    echo $DELIMITADOR
    echo "Selecione o item:" 
    select OPC in "${LISTA[@]}" ; do
     clear 
     echo "Segue as informações do item"
     $CONEXAO -Be "SELECT * FROM produto WHERE NOME = '$OPC';" | awk -F "\t" 'NR!=1{print "ID: "$1"\nNOME: "$2"\nMARCA: "$3"\nESTOQUE: "$4"\nPREÇO: "$5"\n"}'

     REPETICAO=$($CONEXAO -Be "SELECT COUNT(NOME) FROM produto WHERE NOME = '$OPC' ;" | awk -F "\n" 'NR!=1{print $1}')
     if [ $REPETICAO -gt 1 ] ; then
      readarray -t ID< <($CONEXAO -Be "SELECT ID FROM produto WHERE NOME REGEXP '$OPC' ;" | awk -F "\n" 'NR!=1{print $1}')
      NOME_ITEM=$($CONEXAO -Be "SELECT NOME FROM produto WHERE NOME REGEXP '$OPC' ;" | awk -F "\n" 'NR!=1{print $1}')
      echo $DELIMITADOR
      echo "Temos mais de um(a) ${NOME_ITEM}"
      echo "Selecione o ID do item que vai ser alterado:"
      select OPC in "${ID[@]}" ; do
       ITEM=$OPC
       break
      done
     else
      ITEM=$($CONEXAO -Be "SELECT ID FROM produto WHERE NOME = '$OPC';" | awk -F "\t" 'NR!=1{print $1}')
      PRECO=$($CONEXAO -Be "SELECT PRECO FROM produto WHERE ID = $ITEM;" | awk -F "\t" 'NR!=1{print $1}')
     fi
     break
    done
   else
    clear
    $CONEXAO -Be "SELECT * FROM produto WHERE ID = $ITEM;" | awk -F "\t" 'NR!=1{print "ID: "$1"\nNOME: "$2"\nMARCA: "$3"\nESTOQUE: "$4"\nPREÇO: "$5"\n"}'
    ITEM=$($CONEXAO -Be "SELECT ID FROM produto WHERE ID = $ITEM;" | awk -F "\t" 'NR!=1{print $1}')
    PRECO=$($CONEXAO -Be "SELECT PRECO FROM produto WHERE ID = $ITEM;" | awk -F "\t" 'NR!=1{print $1}')
   fi
   while ! [[ $QUANTIDADE =~ ^[0-9]+$ ]]; do
    read -p "Digite a quantidade (aperte somente o ENTER para 1 quantidade): " QUANTIDADE
    if [ -z $QUANTIDADE ] ; then
     QUANTIDADE=1
    fi
   done
   PRECO=$($CONEXAO -Be "SELECT PRECO FROM produto WHERE ID = $ITEM;" | awk -F"\t" 'NR!=1{print $1}')
   echo "Confirma item?"
   select OPC in "SIM" "NÃO" ; do
    if [ $REPLY -eq 1 ] ; then
     CONFIRMA="sim"
     LISTA_ITEM[$COUNT_ITEM]=$ITEM
     QUANTIDADE_LISTA[$COUNT_ITEM]=$QUANTIDADE
     SUBTOTAL=$( echo "$PRECO * $QUANTIDADE + $SUBTOTAL" | bc )
     break
    else
     CONFIRMA="nao"
     break
    fi
   done
   if [ "$CONFIRMA" = "sim" ] ; then
     break
   else
     continue
   fi
  done
   echo "Deseja incluir outro item?"
   select OPC in "SIM" "NÃO" ; do
    if [ $REPLY -eq 1 ] ; then
     CONTINUAR="sim"
     break
    else
     CONTINUAR="nao"
     break
    fi
    if [ "$CONTINUAR" = "sim" ] ; then
     break
    else
     continue
    fi
   done
   if [ "$CONTINUAR" = "sim" ] ; then
    let COUNT_ITEM++
    continue
   else
    break
   fi
 done
}

cliente_registrado
echo $SUBTOTAL
