#! /usr/bin/env bash
#set -x
source variaveis_gerais

campo_mudar(){
 while : ; do
  COUNT=0
  CAMPO=""
  VALOR=""
  clear
  echo $DELIMITADOR
  echo "Qual valor a ser mudado?"
  echo $DELIMITADOR
  select OPC in "NOME" "MARCA" "ESTOQUE" "PREÇO" "DESCRIÇÃO" "VOLTAR"; do
   case $OPC in
    "NOME")
      CAMPO="NOME"
      while [ -z "$VALOR" ] ; do
       read -p "Digite o novo valor para \"NOME\": " VALOR
       VALOR=${VALOR^^}
      done
      break
      ;;
    "MARCA")
      CAMPO="MARCA"
      while [ -z $VALOR ] ; do
       read -p "Digite o novo valor para \"MARCA\": " VALOR
       VALOR=${VALOR^^}
      done
      break;;
    "ESTOQUE")
      CAMPO="ESTOQUE"
      while ! [[ $VALOR =~ ^[0-9]+$ ]] ; do
       read -p "Digite o novo valor para \"ESTOQUE\": " VALOR
      done
      break
      ;;
    "PREÇO")
      CAMPO="PRECO"
      while ! [[ $VALOR =~ ^[0-9]\.+[0-9]+$ ]] ; do
       read -p "Digite o novo valor para \"PREÇO\"(Ex 5.00): " VALOR
      done
      break
      ;;
    "DESCRIÇÃO")
      CAMPO="DESCRICAO"
      read -p "Digite o novo valor para \"DESCRIÇÃO\": " VALOR
      VALOR=${VALOR^^}
      if [ -z $VALOR ] ; then
       VALOR="N/D"
      fi
      break
      ;;
    esac
  done
  echo $DELIMITADOR
  echo "Confirma o campo ${CAMPO} com o valor ${VALOR}?"
  select OPC in "SIM" "NÃO" ; do
   if [ "$OPC" = "SIM" ] ; then
    CONFIRMA="SIM"
    break
   else
    break
   fi
  done
  if [ "${CONFIRMA}" = "SIM" ] ; then
   break
  else
   continue
  fi
 done
 mudar_item
}

consulta_item(){
 while : ; do
  clear
  echo $DELIMITADOR
  echo "Faça a consulta do item:"
  echo $DELIMITADOR
  select OPC in "Nome/ID" "VOLTAR" ; do
   case $OPC in 
    "Nome/ID")
      clear
      while : ; do
       clear
       echo "$DELIMITADOR"
       read -p "Digite o nome ou ID do item: " ITEM
       if [ ! -z "$ITEM" ]; then
        break
       fi
      done
      if [[ $ITEM =~ ^[0-9]+$ ]] ; then
       clear
       echo $DELIMITADOR
       mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "SELECT * FROM produto WHERE ID = $ITEM ;" | awk -F "\t" 'NR!=1{print "Segue os dados do item:\nID: "$1"\nNOME: "$2"\nMARCA: "$3"\nESTOQUE: "$4"\nPREÇO: "$5"\nDESCRIÇÃO: "$6}'
       CONTAGEM=$(mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "SELECT COUNT(ID) FROM produto WHERE ID = $ITEM ;" | awk -F "\n" 'NR!=1{print $1}')
       if [ $CONTAGEM -le 0 ] ; then
        echo $DELIMITADOR
        echo "Sua busca Retornou 0 itens"
        echo "Voltando para o menu...."
        echo $DELIMITADOR
        sleep 2s
        exit 0
       else
        ITEM=${ITEM}
       fi
      else
       clear
       readarray -t LISTA< <(mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "SELECT DISTINCT NOME FROM produto WHERE NOME REGEXP '^$ITEM' ;" | awk -F "\n" 'NR!=1{print $1}')
       echo $DELIMITADOR
       echo "Selecione o item a ser mudado:" 
       select OPC in "${LISTA[@]}" ; do
        clear 
        echo "Segue as informações do item a ser mudado:"
        mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "SELECT * FROM produto WHERE NOME = '$OPC';" | awk -F "\t" 'NR!=1{print "ID: "$1"\nNOME: "$2"\nMARCA: "$3"\nESTOQUE: "$4"\nPREÇO: "$5"\nDESCRIÇÃO: "$6 "\n"}'
        REPETICAO=$(mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "SELECT COUNT(NOME) FROM produto WHERE NOME = '$OPC' ;" | awk -F "\n" 'NR!=1{print $1}')
         if [ $REPETICAO -gt 1 ] ; then
            readarray -t ID< <(mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "SELECT ID FROM produto WHERE NOME REGEXP '$OPC' ;" | awk -F "\n" 'NR!=1{print $1}')
            NOME_ITEM=$(mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "SELECT NOME FROM produto WHERE NOME REGEXP '$OPC' ;" | awk -F "\n" 'NR!=1{print $1}')
            echo $DELIMITADOR
            echo "Temos mais de um(a) ${NOME_ITEM}"
            echo "Selecione o ID do item que vai ser alterado:"
            select OPC in "${ID[@]}" ; do
             ITEM=$OPC
             break
            done
          else
           ITEM=$(mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "SELECT ID FROM produto WHERE NOME = '$OPC';" | awk -F "\t" 'NR!=1{print $1}')
         fi
        break
       done
      fi
      break
      ;;
    esac
  done
   echo $DELIMITADOR
   echo "Confirma o item?"
   select OPC in "SIM" "NÃO" ; do
    if [ $OPC = "SIM" ] ; then
     SAIR="SIM"
     break
    else
     SAIR="NAO"
     break
    fi
   done
   if [ $SAIR = "SIM" ] ; then
    break
   else
    continue
   fi
 done
 campo_mudar
}

mudar_item(){
 clear
   while : ; do
    echo $DELIMITADOR
    echo "Item que vai ser alterado:"
    mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "SELECT * FROM produto WHERE ID = $ITEM ;" | awk -F "\t" 'NR!=1{print "Segue os dados do item:\nID: "$1 "\nNOME: " $2 "\nMARCA: "$3"\nESTOQUE: "$4"\nPREÇO: "$5"\nDESCRIÇÃO: "$6}'
    echo -e "${BLUE_BOLD}${CAMPO}:${END_COLOR} ${RED_BOLD}${VALOR}${END_COLOR} ${WHITE_BLINK}<- NOVO VALOR${END_COLOR}"
    printf "\nConfirma alteração?\n"
    echo -e "${RED_BOLD}ATENÇÃO! Uma vez que confirmada, a mudança vai ser gravada${END_COLOR}"
    select OPC in "SIM" "NÃO" ; do
     case $OPC in
      "SIM")
        if \
mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE << EOF
UPDATE produto SET $CAMPO='$VALOR' WHERE ID = $ITEM
EOF
    then
        clear
        echo "${BLUE_BOLD}Alteração feita com sucesso!!${END_COLOR}"
        mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "SELECT * FROM produto WHERE ID = $ITEM ;" | awk -F "\t" 'NR!=1{print "Segue os dados do item:\nID: "$1"\nNOME: "$2"\nMARCA: "$3"\nESTOQUE: "$4"\nPREÇO: "$5"\nDESCRIÇÃO: " $6 }'

      else
        echo -e "{$RED_BOLD}Falha na alteração${END_COLOR}"
      fi
      break
       ;;
     "NÃO")
       consulta_item
      ;;
     esac
   done
  echo $DELIMITADOR
  echo "Fazer outro item?"
  select OPC in "SIM" "NÃO" ; do
   if [ $OPC = "SIM" ] ; then
      SAIR="SIM"
      break
   else
      SAIR="NAO"
      break
   fi
  done
   case $SAIR in
    "SIM")
       consulta_item
       ;;
    "NAO")
       exit 0
       ;;
    esac
  done
}

consulta_item
