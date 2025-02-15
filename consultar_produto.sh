#! /usr/bin/env bash
source variaveis_gerais
#set -x

#CONSULTA POR NOME E/OU ID DO PRODUTO
consulta_id_nome(){
while : ; do
   clear
   echo "$DELIMITADOR"
   read -p "Digite o NOME/ID do item: " ITEM
   if [[ $ITEM =~ [a-z|A-Z] ]] ;then 
     echo $DELIMITADOR
     echo -e "Segue o retorno do item ${ITEM}"
     mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "SELECT * FROM produto WHERE NOME REGEXP '^[${ITEM}]';" | awk -F "\t" 'NR!=1{print "###########################\n" "ID: "$1"\nNOME: "$2"\nMARCA: "$3"\nESTOQUE: "$4"\nPREÇO: "$5"\nDESCRIÇÃO: " $6"\n" ; if ($4 < 3 ) { print "ATENÇÃO: ESTOQUE BAIXO!\n";}}'
     RETORNO=$(mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "select count(*) count from produto where NOME REGEXP '^[${ITEM}]';" | awk 'NR!=1{print $1}')
     echo $DELIMITADOR
     echo -e "Total de itens econtrados: ${RETORNO}"
     if [ $RETORNO -eq 0 ] ; then
      echo "Sem resultado para o item buscado!"
     fi
   else
     clear
     echo $DELIMITADOR
     echo -e "Segue o retorno do tem:"
     mysql -u$DBUSER -p$DBPASS $BASE -Be "SELECT * FROM produto WHERE ID = ${ITEM} ;" | awk -F "\t" 'NR!=1{print "ID: "$1"\nNOME: "$2"\nMARCA: "$3"\nESTOQUE: "$4"\nPREÇO: "$5"\nDESCRIÇÃO:" $6}'
     RETORNO=$( mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "SELECT COUNT(*) FROM produto WHERE ID= ${ITEM};" | awk 'NR!=1{print $1}')
     ESTOQUE=$( mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "SELECT ESTOQUE FROM produto WHERE ID = ${ITEM};" | awk 'NR!=1{print $1}')
     if [ $ESTOQUE -le 2 ] ; then 
       echo -e "\n${RED_BLINK}ATENÇÃO:\e[0m \e[31mITEM COM ESTOQUE BAIXO!${END_COLOR} \n"
     fi
     echo -e "Total de itens encontrado: ${RETORNO}"
     if [ $RETORNO -eq 0 ] ; then
      echo "Sem resultado para o item buscado!"
     fi
  fi
echo " "
echo "Deseja fazer outra busca?"
 select OPC in "SIM" "NÃO" ; do
  case $OPC in
   "SIM")
     RESP="SIM"
     break
     ;;
   "NÃO")
     RESP="NÃO"
     break
    ;;
  esac
 done
 if [ "${RESP}" = "SIM" ] ; then
  continue
 else
  menu_consulta_item
 fi
done
}

consulta_estoque(){
while : ; do
 clear
 echo $DELIMITADOR
 printf "CONSULTA POR ESTOQUE\nSelecione o tipo de consulta:\n"
 echo $DELIMITADOR

 select OPC in "MAIOR" "MENOR" "ENTRE" "VOLTAR MENU"; do
  case $OPC in
   "MAIOR")
       OPERADOR=">="
       while :; do
        read -p "Digite apartir de qual valor vai ser feita a consulta: " ESTOQUE
         if [ ! -z $ESTOQUE ] ; then
          break
         fi
       done
       break
      ;;
   "MENOR")
       OPERADOR="<="
       while : ; do
         read -p "Digite apartir de qual valor vai ser feita a consulta: " ESTOQUE
         if [ ! -z $ESTOQUE ] ; then
          break
         fi
       done
       break
      ;;
   "ENTRE")
      OPERADOR="BETWEEN"
      while : ; do
       COUNT=0
        while [ $ESTOQUE_INICIAL -ge $ESTOQUE_FINAL ] || [ $ESTOQUE_INICIAL -eq $ESTOQUE_FINAL ] ; do
         printf "Informe o intervalo:\n"
         read -p "Digite o valor inicial: " ESTOQUE_INICIAL
         read -p "Digite o valor final: " ESTOQUE_FINAL
         let COUNT++
          if [ $COUNT -ge 3 ] ; then
           clear
           echo "O valor inicial deve ser MENOR que o final"
           continue
          fi
        done
      if [ ! -z $ESTOQUE_INICIAL ] && [ ! -z $ESTOQUE_FINAL ] ; then
       break
      fi
      done
      break
      ;;
   "VOLTAR MENU")
      menu_consulta_item ;;
  esac
 done

  if [ "$OPERADOR" = "<=" ] ; then
   mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "SELECT * FROM produto WHERE ESTOQUE <= $ESTOQUE ORDER BY ESTOQUE;" | awk -F "\t" 'NR!=1{print "###########################\n" "ID: "$1"\nNOME: "$2"\nMARCA: "$3"\nESTOQUE:  "$4"\nPREÇO: "$5"\nDESCRIÇÃO: " $6"\n" ; if ($4 < 3 ) { print "ATENÇÃO: ESTOQUE BAIXO!\n";}}' 
   RETORNO=$(mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "select count(*) count from produto where ESTOQUE <= $ESTOQUE';" | awk 'NR!=1{print $1}')
   echo $DELIMITADOR
   echo -e "Total de itens econtrados: ${RETORNO}"
   if [ $RETORNO -eq 0 ] ; then
    echo "Sem resultado para o item buscado!"
   fi
  elif [ "$OPERADOR" = ">=" ] ; then
   mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "SELECT * FROM produto WHERE ESTOQUE >= $ESTOQUE ORDER BY ESTOQUE;" | awk -F "\t" 'NR!=1{print "###########################\n" "ID: "$1"\nNOME: "$2"\nMARCA: "$3"\nESTOQUE:  "$4"\nPREÇO: "$5"\nDESCRIÇÃO: " $6"\n" ; if ($4 < 3 ) { print "ATENÇÃO: ESTOQUE BAIXO!\n";}}'
   RETORNO=$(mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "select count(*) count from produto where ESTOQUE >= $ESTOQUE;" | awk 'NR!=1{print $1}')
   echo $DELIMITADOR
   echo -e "Total de itens econtrados: ${RETORNO}"
   if [ $RETORNO -eq 0 ] ; then
    echo "Sem resultado para o item buscado!"
   fi
  else
   mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "SELECT * FROM produto WHERE ESTOQUE BETWEEN $ESTOQUE_INICIAL AND $ESTOQUE_FINAL ORDER BY ESTOQUE;" | awk -F "\t" 'NR!=1{print "###########################\n" "ID: "$1"\nNOME: "$2"\nMARCA: "$3"\nESTOQUE:  "$4"\nPREÇO: "$5"\nDESCRIÇÃO: " $6"\n" ; if ($4 < 3 ) { print "ATENÇÃO: ESTOQUE BAIXO!\n";}}'
   RETORNO=$(mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE -Be "select count(*) count from produto where ESTOQUE BETWEEN $ESTOQUE_INICIAL AND $ESTOQUE_FINAL;" | awk 'NR!=1{print $1}')
   echo $DELIMITADOR
   echo -e "Total de itens econtrados: ${RETORNO}"
   if [ $RETORNO -eq 0 ] ; then
    echo "Sem resultado para o item buscado!"
   fi
  fi
  printf "\nConsultar novamente?\n"
  select RESP in "SIM" "NÃO" ; do
   if [ "$RESP" = "SIM" ] ; then
     consulta_estoque
   else
     menu_consulta_item
   fi
  done
done
}

menu_consulta_item(){
 clear
 echo $DELIMITADOR
 echo "Escolha uma opção de consulta:"
 select OPC in "NOME/ID" "ESTOQUE"; do
 case $OPC in
  "ESTOQUE")
    consulta_estoque
    ;;
  "NOME/ID")
    consulta_id_nome
    ;;
 esac
done
}

menu_consulta_item
