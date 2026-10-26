# Fulltext index regression cases

This directory holds a small semantic regression suite for the fulltext index
(`TOKENIZE` and `MATCH`), next to the performance benchmark.  It is meant to be
run on a server where `tools/benchmark/fts_large_bench.sh` has already loaded the
`fts_large_bench` database (20000 rows, the three fulltext indexes built).

```
MYSQL="mysql -h127.0.0.1 -P2881 -uroot -N -s -A --default-character-set=utf8mb4" \
  bash tools/benchmark/fts_regression/run_fts_regression.sh
```

The script prints one `label<TAB>OK|FAIL` line per case and exits non-zero if
any case fails.  The cases cover:

* `MATCH` hit counts of the natural language mode queries (Chinese, English,
  mixed), which is the auxiliary result check the benchmark reports;
* the doc id order of the `LIMIT` query and of a query with an extra
  `ORDER BY` above the text retrieval scan (the sort above the scan must not
  change the result set);
* `GROUP BY` above the text retrieval scan;
* boolean mode semantics, including the `-` exclusion operator;
* `MATCH` used as a boolean filter, with `AND`/`OR`, and with a score threshold;
* score projection / aggregation and `ORDER BY MATCH(...)`;
* `TOKENIZE` output as a whole (`MD5` of the json text, token order included)
  for the `ik` and `beng` parsers in the default and `all` output modes.

The expectation values are the results of the baseline (unoptimized) server, so
the suite is also usable to compare two server versions.  Note that the score
values themselves are not compared between two servers built from different
data loads; only their presence / relative order is checked here.
