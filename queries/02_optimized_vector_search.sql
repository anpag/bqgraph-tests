-- 1. Build the index with Storing Clause
CREATE OR REPLACE VECTOR INDEX optimized_account_index 
ON `bqgraph-test-489809.bqgraph_test.Account_Large`(embedding) 
STORING(id, account_type) 
OPTIONS(
    distance_type='COSINE', 
    index_type='IVF'
);

-- 2. Execute the optimized search with Pre-filtering
SELECT 
    base.id, 
    base.account_type, 
    distance
FROM VECTOR_SEARCH(
    TABLE `bqgraph-test-489809.bqgraph_test.Account_Large`,
    'embedding',
    (SELECT [0.5, 0.5, 0.5]),
    top_k => 10,
    distance_type => 'COSINE'
)
WHERE base.account_type = 'Checking';
