#! /usr/bin/env bash
source ./variaveis_gerais

#set -x

tipo_alteracao(){
 clear
 local OPC=""
 local OPERACAO=""
 echo "Módulo de alteração de cliente"
 echo "Selecione o tipo de alteração a ser feita"
 select OPC in "MUDAR" "APAGAR" ; do
  if [ "$OPC" = "MUDAR" ] ; then
   OPERACAO="MUDAR"
   break
  else
   OPERACAO="DELETAR"
   break
  fi
 done
 consultar_cliente $OPERACAO
}

#Aqui vamos ter a consulta do cliente, onde faremos a busca, e vamos confirmar se o registro selecionado é que vamos alterar
consultar_cliente(){
while : ; do
  clear
  CLIENTE=""
  local OPERACAO=$1
  local OPC=""
  local CONTAGEM=0
  echo "ALTERAÇÃO DE CLIENTE"
  read -p "Digite o NOME/CPF do cliente: " CLIENTE
  if [[ $CLIENTE =~ [a-z|A-Z] ]] ; then
   mapfile -t LISTA< <($CONEXAO -Be "SELECT NOME_CLIENTE FROM cliente WHERE NOME_CLIENTE REGEXP '^${CLIENTE}';" | awk -F "\n" 'NR!=1{print $1}')
   select OPC in "${LISTA[@]}";do
    CLIENTE="${OPC}"
    break
   done
   clear
   echo "Segue o retorno da consulta para o NOME ${CLIENTE}:"
   $CONEXAO -Be "SELECT * FROM cliente WHERE NOME_CLIENTE REGEXP '${CLIENTE}';" | awk -F "\t" 'NR!=1 {print "\nCPF: " $1"\nNOME: " $2 "\nCOMPRAS: " $3 "\nFIDELIDADE: " $4 "\nDESCONTO: " $5"%"}'
   CLIENTE_MUDAR=$($CONEXAO -Be "SELECT CPF FROM cliente WHERE NOME_CLIENTE = '${CLIENTE}';" | awk -F "\t" 'NR!=1 {print $1}') 
  else
   clear
   echo "Segue o retorno da consulta para o CPF ${CLIENTE}"
   $CONEXAO -Be "SELECT * FROM cliente WHERE CPF = ${CLIENTE};" | awk -F "\t" 'NR!=1 {print "\nCPF: " $1"\nNOME: " $2 "\nCOMPRAS: " $3 "\nFIDELIDADE: " $4 "\nDESCONTO: " $5"%"}'
   CONTAGEM=$($CONEXAO -Be "SELECT COUNT(CPF) FROM cliente WHERE CPF = $CLIENTE;" | awk -F "\t" 'NR!=1 {print $1 }')
   if [ $CONTAGEM -eq 1 ] ; then
    CLIENTE_MUDAR=${CLIENTE}
   else
    echo -e "${RED_BOLD}Nenhum resultado para:${END_COLOR}${BLUE_BOLD}${CLIENTE}${END_COLOR}"
    exit 0
   fi
  fi
  echo -e "\nConfirma Cliente?"
  select OPC in "SIM" "NÃO" ; do
   if [ $REPLY -eq 1 ] ; then
    CONFIRMA="SIM"
    break
   else
    CONFIRMA="NAO"
    break
   fi
  done
  if [ "$CONFIRMA" = "SIM" ] ; then
   break
  else
   continue
  fi
done

if [ "$OPERACAO" = "MUDAR" ] ; then
  campo_mudar
else
  deletar
fi
}

mostrar_resultado(){
 if [ $OPERACAO = "MUDAR" ] ; then
  CABECALHO="Dados do registro a ser ${BLUE_BOLD}mudado${END_COLOR}:"
 else
  CABECALHO="Dados do registro a ser ${RED_BOLD}deletado${END_COLOR}"
 fi
 echo -e $CABECALHO
 $CONEXAO -Be "SELECT * FROM cliente WHERE CPF = $1;" | awk -F "\t" 'NR!=1 {print "\nCPF: " $1"\nNOME: " $2 "\nCOMPRAS: " $3 "\nFIDELIDADE: " $4 "\nDESCONTO: " $5"%"}'
}

campo_mudar(){
 while : ; do
  clear
  VALOR=""
  CAMPO=""
  local OPC=""
  local CONFIRMA=""
  local SAIR=""
  local COUNT=0
  mostrar_resultado $CLIENTE_MUDAR
  echo "Selecione qual campo que vai ser mudado"
  echo -e "\n${RED_BOLD}ATENÇÃO!!!${END_COLOR}\nMudanças nos campos ${BLUE_BOLD}CPF${END_COLOR} e ${BLUE_BOLD}DESCONTO${END_COLOR} não são permitidas.\nNeste caso use a opção ${RED_BOLD}DELETAR${END_COLOR}\n"
  select OPC in "NOME" "FIDELIDADE" "VOLTAR" ; do
   case $OPC in
    "NOME")
      CAMPO="NOME_CLIENTE"
      while [ -z "$VALOR" ] ; do
       clear
       mostrar_resultado $CLIENTE_MUDAR
       echo -e $ALERTA
       read -p "Digite o valor para ${OPC}: " VALOR
       if [ $COUNT -gt 3 ] ; then
        local ALERTA="${RED_BOLD}Esse campo não pode ficar em branco!${END_COLOR}"
       fi
       let COUNT++
      done
      break ;;
    "FIDELIDADE")
      clear
      CAMPO="FIDELIDADE"
      mostrar_resultado $CLIENTE_MUDAR
      echo "Selecione uma das opções abaixo"
      echo -e "\n${RED_BOLD}ATENÇÃO!!!${END_COLOR}\nO valor no campo ${BLUE_BOLD}DESCONTO${END_COLOR} vai ser de acordo com a fidelidade selecionada\n"
      select FIDELIDADE in "STANDARD - Desconto 1%" "SILVER - Desconto 3%" "GOLD - Desconto 5%" "PLATINUM - Desconto 10%" ; do
       case $REPLY in
       1)
        VALOR="STANDARD"
        break;;
       2)
        VALOR="SILVER"
        break;;
       3)
        VALOR="GOLD"
        break ;;
       4)
        VALOR="PLATINUM"
        break ;;
       esac
      done
      break ;;
    "VOLTAR")
       tipo_alteracao
     esac
  done
  clear
  mostrar_resultado $CLIENTE_MUDAR
  echo "Confirma o ${VALOR^^} para o campo $OPC?"
  select CONFIRMA in "SIM" "NÃO" ; do
   if [ $REPLY -eq 1 ] ; then
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
alterar
}

alterar(){
 if [ "$VALOR" = "STANDARD" ] ; then
   DESCONTO=1
   QNT_COMPRAS=10
 elif [ "$VALOR" = "SILVER" ] ; then
   DESCONTO=3
   QNT_COMPRAS=20
 elif [ "$VALOR" = "GOLD" ] ; then
   DESCONTO=5
   QNT_COMPRAS=50
 else
   DESCONTO=10
   QNT_COMPRAS=100
 fi

 if [ "$CAMPO" = "FIDELIDADE" ] ; then
  if \
$CONEXAO << EOF
UPDATE cliente SET ${CAMPO}='${VALOR}', QNT_COMPRAS=${QNT_COMPRAS}, DESCONTO=${DESCONTO} WHERE CPF = ${CLIENTE_MUDAR}
EOF
  then
   echo "Alteração feita com sucesso!"
  else
   echo "Erro no procedimento"
  fi
 else
  if \
$CONEXAO << EOF
UPDATE cliente SET ${CAMPO}='${VALOR^^}' WHERE CPF = ${CLIENTE_MUDAR}
EOF
  then
   echo "Alteração feita com sucesso!"
   tipo_alteracao
  else
   echo "Erro no procedimento!"
   tipo_alteracao
  fi
 fi
}

deletar(){
 clear
 local OPC=""
 mostrar_resultado ${CLIENTE_MUDAR}
 echo -e "\nConfirmar a exclusão?"
 echo -e "${RED_BOLD}ATENÇÃO!${END_COLOR}\nEssa operação ${RED_BLINK}NÃO${END_COLOR} pode ser desfeita"
 select OPC in "SIM" "NÃO" ; do
  case $OPC in
 "SIM")
   if \
$CONEXAO << EOF
DELETE FROM cliente WHERE CPF = ${CLIENTE_MUDAR}
EOF
   then
    echo "Exclusão feita com sucesso"
    tipo_alteracao
   else
    echo "Falha na exclusão"
    tipo_alteracao
   fi
  break;;
 "NÃO")
   tipo_alteracao
   break ;;
  esac
 done
}

tipo_alteracao
