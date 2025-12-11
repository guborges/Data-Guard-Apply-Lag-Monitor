#!/usr/bin/env bash
#
# dg_apply_lag.sh
#
# Oracle Data Guard Apply Lag monitor
# - Conecta no standby
# - Lê value e time_computed de v$dataguard_stats (name = 'apply lag')
# - Converte o value para segundos
# - Imprime lag e status
#
# Created by: Gustavo Borges Evangelista

# Limites em segundos
WARN_THRESHOLD=60      # 1 minuto
CRIT_THRESHOLD=300     # 5 minutos

CONNECT_STRING="$1"

error_exit() {
  echo "ERROR: $1"
  exit 1
}

check_env() {
  if ! command -v sqlplus >/dev/null 2>&1; then
    error_exit "sqlplus not found in PATH. Set ORACLE_HOME and PATH."
  fi

  if [ -z "$CONNECT_STRING" ] && [ -z "$ORACLE_SID" ]; then
    error_exit "ORACLE_SID not set and no connect string provided."
  fi
}

run_sql() {
  if [ -n "$CONNECT_STRING" ]; then
    sqlplus -s "$CONNECT_STRING" <<'EOF'
SET PAGES 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF LINES 200 COLSEP '|' TRIMSPOOL ON
SELECT value, time_computed
  FROM v$dataguard_stats
 WHERE name = 'apply lag';
EXIT
EOF
  else
    sqlplus -s "/ as sysdba" <<'EOF'
SET PAGES 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF LINES 200 COLSEP '|' TRIMSPOOL ON
SELECT value, time_computed
  FROM v$dataguard_stats
 WHERE name = 'apply lag';
EXIT
EOF
  fi
}

########################################
# Main
########################################

check_env

RESULT="$(run_sql)"

# Remove linhas vazias e pega só a primeira (caso viesse mais de uma)
RESULT="$(echo "$RESULT" | sed '/^$/d' | head -n 1)"

# Se vier ORA-*, mostra e sai
if echo "$RESULT" | grep -q "ORA-"; then
  echo "$RESULT"
  error_exit "Oracle error while querying v$dataguard_stats."
fi

if [ -z "$RESULT" ]; then
  error_exit "No APPLY LAG information found in v$dataguard_stats."
fi

# Esperado algo como:
# +00 00:00:00|12/11/2025 17:42:56
LAG_VALUE="${RESULT%%|*}"
TIME_COMPUTED="${RESULT#*|}"

# Limpa espaços
LAG_VALUE="$(echo "$LAG_VALUE" | xargs)"
TIME_COMPUTED="$(echo "$TIME_COMPUTED" | xargs)"

if [ -z "$LAG_VALUE" ]; then
  error_exit "Could not parse apply lag value."
fi

# Remove '+' inicial se tiver
LAG_CLEAN="${LAG_VALUE#+}"

# Remove fração (.000) se existir
LAG_CLEAN="${LAG_CLEAN%%.*}"

# Pode vir como "00 00:00:00" (DD HH:MI:SS) ou "00:00:00" (HH:MI:SS)
read -r FIRST SECOND <<< "$LAG_CLEAN"

if [ -z "$SECOND" ]; then
  # Formato HH:MI:SS
  DAYS=0
  HMS="$FIRST"
else
  # Formato DD HH:MI:SS
  DAYS="$FIRST"
  HMS="$SECOND"
fi

IFS=':' read -r HOUR MIN SEC <<< "$HMS"

DAYS=${DAYS:-0}
HOUR=${HOUR:-0}
MIN=${MIN:-0}
SEC=${SEC:-0}

# Converte pra inteiro (forçando base 10)
DAYS=$((10#$DAYS))
HOUR=$((10#$HOUR))
MIN=$((10#$MIN))
SEC=$((10#$SEC))

TOTAL_SECONDS=$(( SEC + MIN*60 + HOUR*3600 + DAYS*86400 ))

STATUS="OK"
if [ "$TOTAL_SECONDS" -ge "$CRIT_THRESHOLD" ]; then
  STATUS="CRITICAL"
elif [ "$TOTAL_SECONDS" -ge "$WARN_THRESHOLD" ]; then
  STATUS="WARNING"
fi

echo "Apply Lag     : $LAG_VALUE"
echo "Time Computed : $TIME_COMPUTED"
echo "Lag (seconds) : $TOTAL_SECONDS"
echo "Status        : $STATUS"

if [ "$STATUS" = "OK" ]; then
  exit 0
elif [ "$STATUS" = "WARNING" ]; then
  exit 1
elif [ "$STATUS" = "CRITICAL" ]; then
  exit 2
else
  exit 3
fi
