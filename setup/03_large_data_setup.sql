-- Create a large synthetic dataset for vector search performance testing
-- This generates 500,000 rows with 3-dimensional random embeddings
-- Note: BigQuery requires tables to be at least ~10MB to enable vector indexing.
CREATE OR REPLACE TABLE `bqgraph-test-489809.bqgraph_test.Account_Large` AS
SELECT 
  id,
  IF(MOD(id, 2) = 0, 'Checking', 'Savings') as account_type,
  [RAND(), RAND(), RAND()] as embedding
FROM UNNEST(GENERATE_ARRAY(1, 500000)) as id;
