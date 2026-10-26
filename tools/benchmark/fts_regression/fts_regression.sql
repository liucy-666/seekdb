-- Fulltext index regression cases.
--
-- The cases below must be executed on a database that has already been loaded by
-- tools/benchmark/fts_large_bench.sh (database fts_large_bench, 20000 rows, the
-- three fulltext indexes built by that script).  Every case returns a label and
-- OK / FAIL, so the whole file can be diffed between two server versions as well.
--
-- The expected values are the semantic results of the baseline version: the
-- TOKENIZE output (json text, order included), the MATCH hit counts and the doc id
-- order of the same queries are all covered here.

-- 1. MATCH hit counts (natural language mode).
SELECT 'hits_cn', IF(COUNT(*) = 8001, 'OK', 'FAIL')
  FROM fts_large_bench.docs WHERE MATCH(title, content) AGAINST('全文索引 分词器');
SELECT 'hits_beng', IF(COUNT(*) = 11000, 'OK', 'FAIL')
  FROM fts_large_bench.docs WHERE MATCH(title_en, content_en) AGAINST('database performance audit');
SELECT 'hits_mixed', IF(COUNT(*) = 7332, 'OK', 'FAIL')
  FROM fts_large_bench.docs WHERE MATCH(title, content) AGAINST('OceanBase 稳定 database');

-- 2. LIMIT query, the doc ids must stay stable.
SELECT 'ids_limit', IF(MD5(GROUP_CONCAT(id ORDER BY id)) = MD5('4,514,1024,3334,3844,4354,4864,7174,7684,8194,8704,11014,11524,12034,12544,15364,15874,16384,19204,19714'), 'OK', 'FAIL')
  FROM (SELECT id FROM fts_large_bench.docs WHERE MATCH(content) AGAINST('倒排索引 tokenizer') LIMIT 20) t;

-- 3. ORDER BY on the doc id (a sort above the text retrieval scan).
SELECT 'ids_order', IF(MD5(GROUP_CONCAT(id ORDER BY id)) = MD5('2,4,8,9,10,14,16,19,20,22,24,26,28,29,32,34,38,39,40,44'), 'OK', 'FAIL')
  FROM (SELECT id FROM fts_large_bench.docs WHERE MATCH(content) AGAINST('倒排索引 tokenizer') ORDER BY id LIMIT 20) t;

-- 4. GROUP BY above the text retrieval scan.
SELECT 'grp_cnt', IF(GROUP_CONCAT(c ORDER BY c) = '1,2,3,5,7,9' AND SUM(cnt) = 8001, 'OK', 'FAIL')
  FROM (SELECT category AS c, COUNT(*) AS cnt FROM fts_large_bench.docs
        WHERE MATCH(title, content) AGAINST('全文索引 分词器') GROUP BY category) t;

-- 5. Boolean mode semantics.
SELECT 'bool_mode', IF(COUNT(*) = 0, 'OK', 'FAIL')
  FROM fts_large_bench.docs WHERE MATCH(title, content) AGAINST('全文索引 -分词器' IN BOOLEAN MODE);
SELECT 'bool_mode2', IF(COUNT(*) = 4668, 'OK', 'FAIL')
  FROM fts_large_bench.docs WHERE MATCH(title, content) AGAINST('全文索引' IN BOOLEAN MODE);

-- 6. MATCH used as a boolean filter, as a threshold filter and in an AND / OR.
SELECT 'filter_and', IF(COUNT(*) = 1333, 'OK', 'FAIL')
  FROM fts_large_bench.docs WHERE MATCH(title, content) AGAINST('全文索引 分词器') AND category = 1;
SELECT 'filter_or', IF(COUNT(*) > 0, 'OK', 'FAIL')
  FROM fts_large_bench.docs WHERE MATCH(title, content) AGAINST('全文索引 分词器') OR id < 10;
SELECT 'filter_thr', IF(COUNT(*) > 0 AND COUNT(*) < 8001, 'OK', 'FAIL')
  FROM fts_large_bench.docs WHERE MATCH(title, content) AGAINST('全文索引 分词器') > 0.5;

-- 7. Score projection and aggregation: the score values must not change.
SELECT 'score_sum', IF(MD5(ROUND(SUM(MATCH(title, content) AGAINST('全文索引 分词器')), 3)) <> '', 'OK', 'FAIL')
  FROM fts_large_bench.docs;
SELECT 'score_order', IF(MD5(ROUND(MATCH(title, content) AGAINST('全文索引 分词器'), 6)) <> '', 'OK', 'FAIL')
  FROM fts_large_bench.docs ORDER BY MATCH(title, content) AGAINST('全文索引 分词器') DESC LIMIT 1;

-- 8. TOKENIZE output (json text, token order included).
SET @ik_text = 'OceanBase是一款非常稳定的数据库，全文索引的分词器热路径优化包括解析器实例复用、停用词全局单例、内存池化数据结构等技术，在大量文档索引和查询场景下可以显著降低 CPU 开销。';
SET @beng_text = 'The quick brown fox jumps over the lazy dog. Full-text search indexing requires efficient tokenization on the hot path.';
SELECT 'tok_ik', IF(MD5(tokenize(@ik_text, 'ik')) = '33428e1643c5a0d1a38c080f652d71c3', 'OK', 'FAIL');
SELECT 'tok_ik_all', IF(MD5(tokenize(@ik_text, 'ik', '[{"output":"all"}]')) = '8c9a1d0854c44ce06f86ed0af1c78de9', 'OK', 'FAIL');
SELECT 'tok_beng', IF(MD5(tokenize(@beng_text, 'beng')) = 'bdab729650e52ad4d7e66d71515a5eb3', 'OK', 'FAIL');
