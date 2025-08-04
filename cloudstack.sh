#!/bin/bash

# Configurações da API
API_URL="http://192.168.10.2:8080/client/api"
API_KEY="${API_KEY:?API_KEY não definida}"
SECRET_KEY="${SECRET_KEY:?SECRET_KEY não definida}"

# IDs das instâncias
INSTANCE_IDS=("afc83d3e-5686-424c-9330-e2cb2666817d" "208a91a0-7b50-4965-9a02-cedd971ded8c")

# Gera assinatura corretamente
generate_signature() {
    local query_string=$1
    local sig=$(echo -n "$query_string" \
        | tr '[:upper:]' '[:lower:]' \
        | sed -e 's/ /%20/g' \
        | openssl dgst -sha1 -hmac "$SECRET_KEY" -binary \
        | base64 \
        | sed -e 's/+/%2B/g' -e 's/\//%2F/g' -e 's/=/%3D/g')
    echo "$sig"
}

# Envia requisição assinada
send_request() {
    local command=$1
    local instance_id=$2

    local params="apikey=$API_KEY&command=$command&id=$instance_id"
    local sig=$(generate_signature "$params")
    local url="$API_URL?$params&signature=$sig"

    # Executa a requisição
    response=$(curl -s "$url")
    echo "$response"
}

# Funções principais
ligar_instancia() {
    local id=$1
    echo "🔌 Ligando $id..."
    send_request "startVirtualMachine" "$id"
}

desligar_instancia() {
    local id=$1
    echo "🛑 Desligando $id..."
    send_request "stopVirtualMachine" "$id"
}

# Alterna ligar/desligar por 2000 ciclos de 3 em 3 minutos
for (( i=0; i<2000; i++ )) do

	index_on=$((i % 2))
	index_off=$(((i + 1) % 2))
	
	id_on="${INSTANCE_IDS[$index_on]}"
    id_off="${INSTANCE_IDS[$index_off]}"
	
	echo "==================================="
	echo "$(date "+%H:%M:%S - %d/%m/%Y")"
	echo "Ligando instância: $id_on"
	ligar_instancia "$id_on"

	echo "Desligando instância: $id_off"
	desligar_instancia "$id_off"
	echo "==================================="

	echo "⏳ Aguardando 180 segundos..."
	sleep 180
done