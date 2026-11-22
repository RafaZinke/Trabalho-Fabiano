#!/bin/bash
set -euo pipefail
umask 022

ARQUIVO="${1:?Informe o pacote}"
VERSAO="${2:?Informe o commit}"

if [[ ! "$VERSAO" =~ ^[0-9a-f]{40}$ ]]; then
  echo "Identificador de versao invalido."
  exit 1
fi

BASE="/opt/fabiano"
mkdir -p "$BASE/releases"

NOVA=$(mktemp -d "$BASE/releases/${VERSAO}.XXXXXX")
chmod 755 "$NOVA"

tar --no-same-owner -xzf "$ARQUIVO" -C "$NOVA"

python3.12 -m venv "$NOVA/venv"

"$NOVA/venv/bin/python" -m pip install \
  --no-index \
  --find-links="$NOVA/wheelhouse" \
  -r "$NOVA/requirements.txt"

"$NOVA/venv/bin/python" -m pip check

PASTA_SERVICO="/etc/systemd/system/fabiano.service.d"
CONFIG="$PASTA_SERVICO/versao.conf"
BACKUP=$(mktemp)
TEM_ANTERIOR=0

mkdir -p "$PASTA_SERVICO"

if [[ -f "$CONFIG" ]]; then
  cp "$CONFIG" "$BACKUP"
  TEM_ANTERIOR=1
fi

cat > "$CONFIG" <<EOF
[Service]
WorkingDirectory=$NOVA
ExecStart=
ExecStart=$NOVA/venv/bin/gunicorn --workers 1 --threads 2 --bind 0.0.0.0:8000 --access-logfile - --error-logfile - app:app
EOF

systemctl daemon-reload

if systemctl restart fabiano && \
  curl --fail --silent --show-error \
    --retry 10 --retry-connrefused --retry-delay 2 \
    --max-time 5 \
    http://127.0.0.1:8000/health
then
  echo
  echo "Publicacao concluida: $VERSAO"
  exit 0
fi

echo "Falha na nova versao. Restaurando servico anterior."

if [[ "$TEM_ANTERIOR" -eq 1 ]]; then
  cp "$BACKUP" "$CONFIG"
else
  rm -f "$CONFIG"
fi

systemctl daemon-reload
systemctl restart fabiano
exit 1