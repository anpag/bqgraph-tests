# BigQuery Graph with Vector Search Integration

This project demonstrates how to leverage BigQuery Graph in combination with Vector Search embeddings. This allows for hybrid retrieval strategies: identifying semantic similarity using embeddings, and then traversing a complex property graph to uncover relationships and patterns based on those identified nodes.

## Use Case
We model a simple financial graph (`FinGraph`) to detect fraudulent activities. We have `Person` nodes and `Account` nodes. Accounts contain pre-calculated embeddings. Using `VECTOR_SEARCH`, we find accounts structurally or semantically similar to a known fraudster's account, and then we traverse the graph to identify chains of money transfers leading to these suspicious accounts.

## Directory Structure
- `setup/`: Contains DDL and DML scripts to instantiate the tables, populate mock data, and define the property graph.
- `queries/`: Contains the actual GoogleSQL / GQL queries blending vector search with graph traversal.

## Prerequisites
- Access to the Google Cloud Project: `bqgraph-test-489809`
- BigQuery Data Editor permissions to create datasets, tables, and execute queries.

## Instructions to Recreate

### 1. Set Up Data & Mock Embeddings
Run the script in `setup/01_setup_data.sql` within the BigQuery Console. 

This will:
- Create the dataset `bqgraph_test`
- Create node tables (`Person`, `Account`)
- Create edge tables (`Owns`, `Transfers`) with explicitly generated UUIDs as `edge_id` to strictly satisfy BigQuery Graph's primary key constraints.
- Insert mock records, including `ARRAY<FLOAT64>` embeddings for the accounts.

### 2. Define the Property Graph
Run the script in `setup/02_create_graph.sql` within the BigQuery Console.

This script executes the ISO GQL `CREATE PROPERTY GRAPH` statement. It properly maps the node and edge tables, referencing the unique `edge_id` keys as mandated by BigQuery's constraints for unstructured/generated edge sources.

### 3. Run the Hybrid Vector + Graph Query
Execute the script found in `queries/01_vector_search_and_graph.sql`.

**What it does:**
1. It uses BigQuery's `VECTOR_SEARCH` to compare the `embedding` column of all accounts against the embedding of the known fraudster's account (`id = 102`), returning the `top_k` (2) most similar accounts.
2. It takes those similar account IDs and runs a variable-length graph traversal (`->{1,6}`) using GoogleSQL's `GRAPH_TABLE` function to find all people and transfer activities that lead into these suspicious accounts.

*Note: The script includes both the `GRAPH_TABLE` (GoogleSQL) implementation and the standard GQL syntax implementation in the comments.*

## Query Approaches

There are two ways to query the graph in BigQuery, shown in the script.

### Approach A: Native GQL
This uses the standalone GRAPH keyword. It is the best choice when you only need to traverse the graph. 

It cleanly accepts variables and arrays directly in the WHERE clause. However, you cannot easily combine it with standard SQL aggregations or joins in the same query.

### Approach B: GoogleSQL GRAPH_TABLE
This wraps the graph traversal inside a standard SELECT statement. 

It is very powerful because you can use the output to perform standard SQL joins and aggregations. 

The downside is that it currently does not accept variables inside the MATCH or WHERE clauses. You have to use dynamic SQL (EXECUTE IMMEDIATE) to inject variables into the query string.