#!/bin/sh
set -e

echo "Inicializando Redis…"

/usr/local/bin/redis-server /etc/redis/redis.conf &
REDIS_PID=$!

echo "Aguardando Redis responder..."
until redis-cli PING >/dev/null 2>&1; do
    sleep 0.5
done

echo "Inserindo valores iniciais..."
redis-cli SET teste_ff0ddb1f-f91e-4d4a-9555-ccabd86e8da6 10000

echo "Seed concluído!"
wait $REDIS_PID
