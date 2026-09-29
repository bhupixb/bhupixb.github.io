#!/usr/bin/env bash
set -euo pipefail

PSQL=(psql -X -d exp -U ybcloud)
PGBENCH=(pgbench -d exp -U ybcloud -n -c 8 -j 8 -T 10 -r --failures-detailed)

mkdir -p benchmark-results

reset_table() {
  "${PSQL[@]}" -v ON_ERROR_STOP=1 -f benchmark-setup.sql >/dev/null
}

run_case() {
  local case_name="$1"
  local max_tries="$2"
  local run_number="$3"
  "${PGBENCH[@]}" --max-tries="$max_tries" -f transaction.sql \
    > "benchmark-results/${case_name}-${run_number}.txt" 2>&1
}

for run_number in 1 2 3; do
  reset_table
  "${PSQL[@]}" -Atc "EXPLAIN (COSTS OFF) SELECT balance FROM serializable_accounts WHERE external_id = 10001" \
    > "benchmark-results/no-index-plan-${run_number}.txt"
  run_case no-index 1 "$run_number"
done

for run_number in 1 2 3; do
  reset_table
  "${PSQL[@]}" -v ON_ERROR_STOP=1 -c \
    "CREATE INDEX serializable_accounts_external_id_idx ON serializable_accounts(external_id); ANALYZE serializable_accounts;" \
    >/dev/null
  "${PSQL[@]}" -Atc "EXPLAIN (COSTS OFF) SELECT balance FROM serializable_accounts WHERE external_id = 10001" \
    > "benchmark-results/index-plan-${run_number}.txt"
  run_case with-index 1 "$run_number"
done

reset_table
run_case no-index-retry 10 1
