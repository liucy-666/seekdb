#!/bin/bash
# Run the fulltext index regression cases.
#
# Usage:
#   bash tools/benchmark/fts_regression/run_fts_regression.sh [mysql args...]
#
# The cases expect the fts_large_bench database to be already loaded and indexed,
# which is what tools/benchmark/fts_large_bench.sh leaves behind after a run.
# Example:
#   METRIC_MYSQL="mysql -h127.0.0.1 -P2881 -uroot -N -s -A --default-character-set=utf8mb4" \
#     bash tools/benchmark/fts_regression/run_fts_regression.sh
set -u

MYSQL=${MYSQL:-mysql -h127.0.0.1 -P2881 -uroot -N -s -A --default-character-set=utf8mb4}
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

OUTPUT=$($MYSQL --default-character-set=utf8mb4 < "$SCRIPT_DIR/fts_regression.sql" 2>&1)
RET=$?
if [ $RET -ne 0 ]; then
  echo "$OUTPUT"
  echo "FTS REGRESSION: ERROR (mysql exit code $RET)"
  exit 1
fi

FAILS=$(echo "$OUTPUT" | grep -c 'FAIL')
echo "$OUTPUT"
if [ "$FAILS" -ne 0 ]; then
  echo "FTS REGRESSION: FAILED ($FAILS case(s))"
  exit 1
fi
echo "FTS REGRESSION: PASSED"
