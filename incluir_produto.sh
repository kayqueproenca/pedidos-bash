#! /usr/bin/env bash
source variaveis_gerais

#Inicio da função para coleta de dados.
coleta_info_prod(){
 COUNT=0
 while : ; do
  while true; do
   ID[$COUNT]=""
   NOME[$COUNT]=""
   MARCA[$COUNT]=""
   ESTOQUE[$COUNT]=""
   PRECO[$COUNT]=""
   DESC[$COUNT]=""
   clear
   echo $DELIMITADOR
   echo "Digite as informações do produto"
   echo $DELIMITADOR
   while ! [[ ${ID[$COUNT]} =~ ^[0-9]+$ ]]; do
    read -p "Informe o ID do produto -> " ID[$COUNT]
   done
   while [ -z "${NOME[$COUNT]}" ] ; do
    read -p "Informe o NOME do produto -> " NOME[$COUNT]
   done
   while [ -z "${MARCA[$COUNT]}" ] ;do
    read -p "Informe a MARCA do produto -> " MARCA[$COUNT]
   done
   while ! [[ ${ESTOQUE[$COUNT]} =~ ^[0-9]+$ ]] ; do
    read -p "Informe o ESTOQUE inicial do produto -> " ESTOQUE[$COUNT]
   done
   while ! [[ ${PRECO[$COUNT]} =~ ^[0-9]+\.[0-9]+$ ]] ; do
    read -p "Informe o PREÇO do produto (Ex. 5.00) -> " PRECO[$COUNT]
   done
   read -p "Informe uma breve descrição do produto (opcional) -> " DESC[$COUNT]
   if [ -z "${DESC[$COUNT]}" ] ; then
     DESC[$COUNT]="N/D"
   fi
   clear
   echo $DELIMITADOR
   echo "Segue o retorno dos itens: "
   echo $DELIMITADOR
   echo "ID: ${ID[$COUNT]}"
   echo "NOME: ${NOME[$COUNT]}"
   echo "MARCA: ${MARCA[$COUNT]}"
   echo "ESTOQUE INICIAL: ${ESTOQUE[$COUNT]}"
   echo "PREÇO: ${PRECO[$COUNT]}"
   echo "DESCRIÇÃO: ${DESC[$COUNT]}"
   echo " "
   echo "Confirma os dados acima?"
   select OPC in "SIM" "NÃO" ; do
    case $OPC in
     SIM)
      RESP="SIM"
      break
       ;;
     NÃO)
      RESP="NAO"
      break
       ;;
     esac
    done
    if [ "${RESP}" = "SIM" ] ; then
     break
    else
     continue
    fi
 done
 clear
  echo "Deseja incluir outro produto?"
  select OPC in "SIM" "NÃO" ; do
    case $OPC in
     SIM)
      RESP="SIM"
      break
       ;;
     NÃO)
      RESP="NÃO"
      break
       ;;
     esac
    done
    if [ "${RESP}" = "NÃO" ] ; then
     break
    else
     let COUNT++
     continue
    fi
 done
 inclusao_prod
#Fim da função de coleta de dados.
}

inclusao_prod(){
if [ $COUNT -gt 1 ] ; then
 echo "Fazendo a inclusão dos itens..."
 sleep 0.5s
else
 echo "Fazendo a inclusão do item..."
 sleep 0.5s
fi
for (( i=0 ; i <= $COUNT ; i++ )) ; do
 if \
mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE << EOF 2>> erro.log
insert into produto (ID,NOME, MARCA,ESTOQUE, PRECO, DESCRICAO) values (${ID[$i]}, '${NOME[$i]}','${MARCA[$i]}', ${ESTOQUE[$i]}, ${PRECO[$i]}, '${DESC[$i]}');
EOF
 then
  echo $DELIMITADOR
  echo "Inclusão do ${NOME[$i]} feita com sucesso! "
  echo $DELIMITADOR
 else
  echo $DELIMITADOR
  printf "Inclusão do ${NOME[$i]} com falha!!\nFavor verificar o log erro.log\n"
  echo $DELIMITADOR
 fi
done
}

coleta_info_prod
