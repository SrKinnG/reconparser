#!/bin/bash

# ==================================================
# ReconParser
# Versão: 1
# Desenvolvimento: srkinng
# ==================================================

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

banner() {

echo -e "${CYAN}"
echo "=========================================="
echo "            ReconParser v1"
echo "        Desenvolvimento: srkinng"
echo "=========================================="
echo -e "${NC}"

}

if [ -z "$1" ]; then
echo -e "${RED}Uso: $0 dominio.com${NC}"
exit
fi

alvo=$1

if [[ ! $alvo =~ ^https?:// ]]; then
    alvo="http://$alvo"
fi

pasta="recon-$1"

mkdir -p $pasta

hosts="$pasta/hosts.txt"
ips="$pasta/ips.txt"
online="$pasta/online.txt"

tmp=$(mktemp)

banner

echo -e "${YELLOW}[1] Baixando página...${NC}"
wget -q -O $tmp $alvo

echo -e "${YELLOW}[2] Fazendo parsing de hosts...${NC}"

cat $tmp | \
grep href | \
cut -d "/" -f 3 | \
grep "\." | \
cut -d '"' -f 1 | \
grep -v "<l" | \
sort -u > $hosts

rm $tmp

echo -e "${GREEN}Hosts encontrados:${NC}"
cat $hosts

echo
echo -e "${YELLOW}[3] Resolvendo IPs...${NC}"

> $ips

for host in $(cat $hosts)
do

ip=$(dig +short $host | head -n1)

if [ ! -z "$ip" ]; then
echo "$host -> $ip" >> $ips
fi

done

cat $ips

echo
echo -e "${YELLOW}[4] Verificando hosts online (modo rápido)...${NC}"

> $online

cat $hosts | xargs -I{} -P 20 bash -c '
status=$(curl -o /dev/null -s -w "%{http_code}" --connect-timeout 3 http://{})
if [[ "$status" == "200" || "$status" == "301" || "$status" == "302" ]]; then
echo "{} ONLINE ($status)"
fi
' >> $online

cat $online

echo
echo -e "${GREEN}Recon finalizado!${NC}"

echo
echo "Resultados em:"
echo "$pasta/"
