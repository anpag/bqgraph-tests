-- 1. Find accounts with similar embeddings to account 102 (Fraudster's account)
DECLARE similar_account_to_fraudster ARRAY<INT64> DEFAULT ((
  SELECT array_agg(vs.base.id)
  FROM VECTOR_SEARCH(
    TABLE `bqgraph-test-489809.bqgraph_test.Account`,
    'embedding',
    (SELECT * FROM `bqgraph-test-489809.bqgraph_test.Account` WHERE id = 102),
    'embedding',
    top_k => 2
  ) AS vs
));

-- 2. Query the graph to find transfer activities related to these similar accounts
-- Approach A: Standard ISO GQL approach (Native Graph Execution)
GRAPH `bqgraph-test-489809.bqgraph_test.FinGraph`
MATCH (person:Person)-[own:Owns]->(account:Account)-[transfer:Transfers]->{1,6}(to_account:Account)
WHERE to_account.id IN UNNEST(similar_account_to_fraudster)
RETURN 
  person.name AS person_name,
  account.id AS account_id,
  to_account.id AS to_account_id;

/*
-- Approach B: GoogleSQL GRAPH_TABLE approach using Dynamic SQL
EXECUTE IMMEDIATE format("""
SELECT * FROM GRAPH_TABLE(
  `bqgraph-test-489809.bqgraph_test.FinGraph`
  MATCH (person:Person)-[own:Owns]->(account:Account)-[transfer:Transfers]->{1,6}(to_account:Account)
  WHERE to_account.id IN (%s)
  COLUMNS (
    person.name AS person_name,
    account.id AS account_id,
    to_account.id AS to_account_id
  )
)
""", (SELECT STRING_AGG(CAST(id AS STRING), ',') FROM UNNEST(similar_account_to_fraudster) AS id));
*/