-- Create a large synthetic dataset for vector search performance testing
-- This generates 10,000 rows with 3-dimensional random embeddings
CREATE OR REPLACE TABLE `bqgraph-test-489809.bqgraph_test.Account_Large` AS
SELECT 
  id,
  IF(MOD(id, 2) = 0, 'Checking', 'Savings') as account_type,
  [RAND(), RAND(), RAND()] as embedding
FROM UNNEST(GENERATE_ARRAY(1, 10000)) as id;
