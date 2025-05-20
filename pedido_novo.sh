#! /usr/bin/env bash

#USA VARIAVEIS IMPORTANTES, COMO A $CONEXAO, QUE DÁ ACESSO AO BANCO DE DADOS, ENTRE OUTRAS, COMO AS QUE DEFINEM AS CORES
source ./variaveis_gerais

#set -x

#CONSULTA DO CLIENTE, CASO ELE SEJA REGISTRADO
cliente_registrado(){
 CLIENTE=""
 CLIENTE_PEDIDO=""
 DESCONTO=0
 local AVISO=""
 local COUNT=0
 local LISTA_CLIENTE=()
 local QNT_RESULTADO=0
 while : ; do
  clear
  echo $DELIMITADOR
  echo "Cliente registrado?"
  select OPC in "SIM" "NÃO" ; do
    if [ $REPLY -eq 1 ] ; then
    while [ $QNT_RESULTADO -eq 0 ]; do
     clear
     CLIENTE=""
     echo $DELIMITADOR
     echo -e $AVISO
      read -p "Informe o NOME/CPF do cliente: " CLIENTE #Neste campo, podemos por o nome, ou o CPF do cliente, caso exista, vamos ter um retorno, se for informado o nome, vamos ter uma lista de clientes, se tiver mais de um, o CPF, por ser único, mostra de forma direta
      AVISO=""
      #Aqui temos um procedimento que vai verificar se o valor buscado, seja nome ou CPF, existe de fato lá no banco, com isso podemos prosseguir, caso tivermos um retorno maior que zero, caso contrário, vamos ter uma mensagem de erro, informando que o valor buscado não tem registro, e vai pedir para por um outro valor.
      if [[ $CLIENTE =~ ^[a-z|A-Z] ]] ;then
        QNT_RESULTADO=$( $CONEXAO -Be "SELECT COUNT(NOME_CLIENTE) FROM cliente WHERE NOME_CLIENTE REGEXP '^$CLIENTE';" 2> /dev/null | awk -F "\n" 'NR!=1 {print $1}')
      elif [[ $CLIENTE =~ ^[0-9]+$ ]];then
        QNT_RESULTADO=$( $CONEXAO -Be "SELECT COUNT(NOME_CLIENTE) FROM cliente WHERE CPF = $CLIENTE;" 2> /dev/null | awk -F "\n" 'NR!=1 {print $1}')
      else
        AVISO="O campo não pode ficar em branco"
      fi
       if [ $QNT_RESULTADO -eq 0 ] ; then
         AVISO="${RED_BOLD}Nenhum resultado encontrado para:${END_COLOR} ${CLIENTE}"
       fi
     done
     #Fim do procedimento.

     if [[ $CLIENTE =~ ^[a-z|A-Z] ]]; then #Caso a busca seja feita por nome, vamos ter uma expressão REGEX, que vai fazer a busca, e vamos ter uma lista com possíveis nome como retorno, podemos ter mais de um registro, tudo depende de como a busca foi feita.
       mapfile -t LISTA_CLIENTE< <($CONEXAO -Be "SELECT NOME_CLIENTE FROM cliente WHERE NOME_CLIENTE REGEXP '^$CLIENTE';" | awk -F "\n" 'NR!=1 {print $1}') #Por padrão o retorno é linhas, o mapfile pega essas linhas, e coloca em um array, que vamos poder usar no select, trata-se de um comando built-in :-)
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
         DESCONTO=$($CONEXAO -Be "Select DESCONTO FROM cliente WHERE CPF = $CLIENTE_PEDIDO;" | awk -F"\t" 'NR!=1 {print $1}') #Aqui, vamos pegar o valor que temos na coluna "desconto" que temos no banco, temos que por esse valor em uma variavel propria, já que vamos utilizar esse valor lá na frente.
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
     QNT_RESULTADO=0
     CLIENTE=""
     break
   else
    clear
    echo "Cancelando pedido..."
    CLIENTE_PEDIDO=""
    QNT_RESULTADO=0
    CLIENTE=""
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

#EXCLUSIVA PARA SOMENTE MOSTRAR O CLIENTE QUE FOI CONSULTADO
mostrar_cliente(){
 if [ $1 -eq 11111111111 ] ; then #Aqui, caso o cliente não seja cadastrado, vamos por um número genérico, que não vai ser usado, como CPF, e ele vai ser registrado no banco, e vai informar que o cliente em questão não existe, e não vai desconto.
  echo -e "Compra com cliente não cadastrado\n${RED_BOLD}SEM DIREITO A DESCONTO FIDELIDADE${END_COLOR}"
 else
  $CONEXAO -Be "SELECT CPF, NOME_CLIENTE, FIDELIDADE FROM cliente WHERE CPF = $1;" | awk -F "\t" 'NR!=1 {print "CPF: "$1"\nNOME: "$2"\nFIDELIDADE: "$3}'
  echo -e "Desconto concedido ${BLUE_BOLD}${DESCONTO}0%${END_COLOR}"
 fi
}

#EXCLUSIVA PARA SOMENTE MOSTRAR OS PRODUTOS QUE FORAM CONSULTADOS, E QUE VÃO SER INTEGRADOS AO PEDIDO
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
   local AVISO=""
   local QNT_ITEM=0
   while [ $QNT_ITEM -eq 0 ] ; do
    clear
    echo $DELIMITADOR
    mostrar_cliente $CLIENTE_PEDIDO
    echo $DELIMITADOR
    echo -e "\nLista de itens:"
    mostrar_produto
    echo -e "\nSubtotal: R\$ ${SUBTOTAL}\n"
    if [ $DESCONTO -gt 0 ] ; then
     echo -e "Subtotal com desconto de ${DESCONTO}0%: R\$ ${SUBTOTAL_DESC}\n"
    fi
    #while [ $QNT_ITEM -eq 0 ] ; do
     echo -e $AVISO
     read -p "Coloque o CÓDIGO/NOME do produto: " ITEM
     if [[ $ITEM =~ ^[A-Z|a-z] ]] ; then
      QNT_ITEM=$($CONEXAO -Be "SELECT COUNT(ID) FROM produto WHERE NOME REGEXP '^$ITEM' ;" | awk -F "\n" 'NR!=1{print $1}')
     elif [[ $ITEM  =~ ^[0-9]+$ ]] ; then
      QNT_ITEM=$($CONEXAO -Be "SELECT COUNT(ID) FROM produto WHERE ID = $ITEM ;" | awk -F "\n" 'NR!=1{print $1}')
     else
      AVISO="O campo não pode ficar em branco"
     fi
     if [ $QNT_ITEM -eq 0 ] ; then
      AVISO="${RED_BOLD}NENHUM RESULTADO PARA O ITEM:${END_COLOR} $ITEM"
     fi
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
     if [ $DESCONTO -eq 0 ]; then
       SUBTOTAL=$( echo "$PRECO * $QUANTIDADE + $SUBTOTAL" | bc )
     else
       SUBTOTAL=$( echo "$PRECO * $QUANTIDADE + $SUBTOTAL" | bc )
       SUBTOTAL_DESC=$(echo "$SUBTOTAL - ($SUBTOTAL * 0.$DESCONTO)" | bc)
     fi
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
 confirmar_compra
}

confirmar_compra() {
 NUMERO_PEDIDO=0
 while : ; do
  clear
  mostrar_cliente $CLIENTE_PEDIDO
  DATA_PEDIDO=$(date +%Y%m%d)
  NUMERO_PEDIDO="${DATA_PEDIDO}${RANDOM}"
  echo -e "${BLUE_BOLD}PEDIDO Nº ${END_COLOR} $NUMERO_PEDIDO"
  echo -e "Lista de produtos:\n"
  mostrar_produto
  echo -e "\nSUBTOTAL R\$ $SUBTOTAL"
  echo -e "SUBTOTAL COM DESCONTO: R\$ $SUBTOTAL_DESC"
  echo "Confirma pedido?"
  select OPC in "SIM" "NÃO" ; do
   if [ $REPLY -eq 1 ] ; then
     SAIR="S"
     break
   else
    SAIR="N"
    echo -e "${RED_BOLD}PEDIDO CANCELADO!${END_COLOR}"
    sleep 1s
    cliente_registrado
   fi
  done
  if [ "$SAIR" = "S" ] ; then
    echo ${LISTA_ITEM[@]}
    break
  fi
 done
}

cliente_registrado
