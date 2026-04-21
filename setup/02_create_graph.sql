-- Global constraints state EVERY table (both NODE TABLES and EDGE TABLES) must have an explicitly defined KEY.
-- Using the explicit uuid keys 'edge_id' generated during the insert.
CREATE OR REPLACE PROPERTY GRAPH `bqgraph-test-489809.bqgraph_test.FinGraph`
  NODE TABLES (
    `bqgraph-test-489809.bqgraph_test.Person` AS Person KEY(id),
    `bqgraph-test-489809.bqgraph_test.Account` AS Account KEY(id)
  )
  EDGE TABLES (
    `bqgraph-test-489809.bqgraph_test.Owns` AS Owns
      KEY(edge_id) 
      SOURCE KEY(person_id) REFERENCES Person(id)
      DESTINATION KEY(account_id) REFERENCES Account(id),
    `bqgraph-test-489809.bqgraph_test.Transfers` AS Transfers
      KEY(edge_id)
      SOURCE KEY(from_account_id) REFERENCES Account(id)
      DESTINATION KEY(to_account_id) REFERENCES Account(id)
  );