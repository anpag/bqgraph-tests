CREATE SCHEMA IF NOT EXISTS `bqgraph-test-489809.bqgraph_test`;

CREATE OR REPLACE TABLE `bqgraph-test-489809.bqgraph_test.Person` (
    id INT64,
    name STRING
);

CREATE OR REPLACE TABLE `bqgraph-test-489809.bqgraph_test.Account` (
    id INT64,
    account_type STRING,
    embedding ARRAY<FLOAT64>
);

CREATE OR REPLACE TABLE `bqgraph-test-489809.bqgraph_test.Owns` (
    edge_id STRING,
    person_id INT64,
    account_id INT64
);

CREATE OR REPLACE TABLE `bqgraph-test-489809.bqgraph_test.Transfers` (
    edge_id STRING,
    from_account_id INT64,
    to_account_id INT64,
    amount FLOAT64
);

INSERT INTO `bqgraph-test-489809.bqgraph_test.Person` (id, name) VALUES
(1, 'Alice'),
(2, 'Bob'),
(3, 'Charlie'),
(102, 'Fraudster');

INSERT INTO `bqgraph-test-489809.bqgraph_test.Account` (id, account_type, embedding) VALUES
(101, 'Checking', [0.1, 0.2, 0.3]),
(102, 'Savings',  [0.9, 0.8, 0.9]), -- Fraudster's account
(103, 'Checking', [0.8, 0.8, 0.9]), -- Similar to fraudster
(104, 'Savings',  [0.2, 0.1, 0.3]);

-- Note: We generate UUIDs for edge table keys to satisfy BigQuery Graph constraints.
INSERT INTO `bqgraph-test-489809.bqgraph_test.Owns` (edge_id, person_id, account_id) VALUES
(GENERATE_UUID(), 1, 101),
(GENERATE_UUID(), 2, 103),
(GENERATE_UUID(), 3, 104),
(GENERATE_UUID(), 102, 102);

INSERT INTO `bqgraph-test-489809.bqgraph_test.Transfers` (edge_id, from_account_id, to_account_id, amount) VALUES
(GENERATE_UUID(), 101, 104, 50.0),
(GENERATE_UUID(), 102, 103, 1000.0),
(GENERATE_UUID(), 103, 104, 500.0);