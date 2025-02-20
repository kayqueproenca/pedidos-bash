#! /usr/bin/env bash

source ./variaveis_gerais

#Caso queira debbugar, descomente a linha abaixo
#set -x

coleta_dados(){
COUNT=0
while : ; do
 while : ; do
  CPF[$COUNT]=""
  NOME_CLIENTE[$COUNT]=""
  clear
  echo $DELIMITADOR
   while ! [[ ${CPF[$COUNT]} =~ ^[0-9]+$ ]]; do
    read -p "DIGITE O CPF DO CLIENTE (SOMENTE NÚMEROS) -> " CPF[$COUNT]
   done

   valida_cpf ${CPF[$COUNT]}

   if [ "$CPF_VALIDO" = "false" ] ; then
    echo -e "${RED_BOLD}CPF INFORMADO INVÁLIDO${END_COLOR}"
    while true ; do
     CPF[$COUNT]=""
     while ! [[ ${CPF[$COUNT]} =~ ^[0-9]+$ ]] ; do
      read -p "DIGITE O CPF DO CLIENTE (SOMENTE NÚMEROS) -> " CPF[$COUNT]
     done
     valida_cpf ${CPF[$COUNT]}
     if [ "${CPF_VALIDO}" = "true" ] ; then
      break
     else
      continue
     fi
    done
   fi

  while [ -z "${NOME_CLIENTE[$COUNT]}" ] ; do
   read -p "DIGITE O NOME DO CLIENTE -> " NOME_CLIENTE[$COUNT]
  done
  clear
  echo $DELIMITADOR
  echo -e "${BLUE_BOLD}CPF DO CLIENTE:${END_COLOR} ${CPF[$COUNT]}"
  echo -e "${BLUE_BOLD}NOME DO CLIENTE:${END_COLOR} ${NOME_CLIENTE[$COUNT]^^}"
  echo -e "\n${RED_BLINK}ATENÇÃO!!!${END_COLOR}\n${WHITE_BOLD}Clientes novos vão receber por padrão a fidelização${END_COLOR} ${YELLOW_BOLD}\"STANDARD\"${END_COLOR}\n"
  echo "Os dados estão certos?"
  select OPC in "SIM" "NÃO" ; do
   if [ $OPC = "SIM" ] ; then
    SAIR="sim"
    break
   else
    SAIR="não"
    break
   fi
  done
  if [ $SAIR = "sim" ] ; then
   break
  else
   continue
  fi
 done
 echo $DELIMITADOR
 echo "Deseja incluir outro cliente?"
 select OPC in "SIM" "NÃO" ; do
  if [ $OPC = "SIM" ] ; then
    CONTINUAR="sim"
    break
  else
    CONTINUAR="não"
    break
  fi
 done
 
 if [ $CONTINUAR = "sim" ] ; then
  let COUNT++
  continue
 else
  break
 fi
done
inclusao_cliente
}

valida_cpf(){
 local MULT=10
 local DV1=0
 local DV2=0
 local SOMA=0
 local CPF=$1
 CPF_DIG=()
 
 for ((i=0; i < ${#CPF}; i++)); do
  CPF_DIG[$i]=${CPF:i:1}
 done

 for (( i=0; i < 9; i++ )); do
  SOMA=$[ (${CPF_DIG[$i]} * $MULT) + $SOMA ]
  MULT=$[ $MULT - 1 ]
 done

 RESTO=$[ $SOMA % 11 ]

 if [ $RESTO -lt 2 ]; then
  DV1=0
 else
  DV1=$[ 11 - $RESTO ]
 fi

 SOMA=0
 MULT=11
 for (( i=0; i < 10; i++ )) ; do
  SOMA=$[ (${CPF_DIG[$i]} * $MULT) + $SOMA ]
  MULT=$[ $MULT - 1 ]
 done

 RESTO=$[ $SOMA % 11 ]

 if [ $RESTO -lt 2 ]; then
  DV2=0
 else
  DV2=$[ 11 - $RESTO ]
 fi

 if [ $DV1 -eq ${CPF_DIG[9]} ] && [ $DV2 -eq ${CPF_DIG[10]} ]; then
  CPF_VALIDO="true"
 else
  CPF_VALIDO="false"
 fi
}

inclusao_cliente(){
for (( i=0 ; i<=$COUNT ; i++ )) ; do
 if \
 mysql -u$DBUSER -p$DBPASS -h$DBHOST $BASE << EOF 2>> erro.log
insert into cliente (CPF, NOME_CLIENTE, QNT_COMPRAS, FIDELIDADE, DESCONTO) values (${CPF[$i]}, '${NOME_CLIENTE[$i]^^}', 0, 'STANDARD', 1);
EOF
 then
  echo -e "${BLUE_BOLD}Inclusão do ${NOME_CLIENTE[$i]} feita com sucesso!${END_COLOR}"
 else
  echo -e "${RED_BOLD}Inclusão do ${NOME_CLIENTE[$i]} com erro!${END_COLOR}"
 fi
done
}

coleta_dados
