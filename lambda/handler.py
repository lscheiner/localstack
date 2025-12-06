import os
import json

def lambda_handler(event, context):
    print("\n=== EVENTO DO DYNAMODB STREAM ===")

    # Imprime JSON formatado
    print("Event (formatado) =>")
    print(json.dumps(event, indent=2, ensure_ascii=False))

    # Captura variáveis de ambiente reais
    env_vars = dict(os.environ)

    # Extrai variáveis mencionadas no JSON
    # (qualquer chave top-level do evento que também exista como env var)
    keys_do_evento = []

    if isinstance(event, dict):
        keys_do_evento = list(event.keys())

    env_vars_usadas = {
        k: env_vars[k]
        if k in env_vars else "(não existe nas variáveis de ambiente)"
        for k in keys_do_evento
    }

    print("\n=== VARIÁVEIS MENCIONADAS NO EVENTO ===")
    print(json.dumps(env_vars_usadas, indent=2, ensure_ascii=False))

    print("\n=== TODAS AS ENV VARS ===")
    print(json.dumps(env_vars, indent=2, ensure_ascii=False))

    return {
        "status": "ok",
        "env_vars_mencionadas": env_vars_usadas,
        "env_vars_todas": env_vars
    }
