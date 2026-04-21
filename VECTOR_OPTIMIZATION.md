# BigQuery Vector Search Optimization

This guide shows you how to optimize vector searches so you aren't stuck with slow, brute-force scans. When you're dealing with graph nodes at scale, these optimizations are what keep your queries fast and your costs down.

## Optimization Mechanisms

### 1. Vector Indexes (ANN)
By default, `VECTOR_SEARCH` is an exact search—it checks every single row. For large datasets, you need a **Vector Index**. This uses Approximate Nearest Neighbor (ANN) to find results way faster.

*   **IVF:** Good for most cases, clusters your data.
*   **TreeAH:** Uses Google's ScaNN algorithm. It's the best choice for large batches and high-performance needs.

### 2. Storing Clause
When you build your index, use the `STORING` clause to keep frequently used columns (like IDs or types) inside the index itself.
*   **Join Elimination:** If your query only asks for columns you've "stored," BigQuery grabs them directly from the index and skips the join to the base table entirely. This is a massive win for performance.

### 3. Pre-filtering & Partition Pruning
*   **Pre-filtering:** If you use a `WHERE` clause on a column included in the `STORING` clause, BigQuery filters the data *before* it even starts the vector math.
*   **Partition Pruning:** If your table is partitioned, BigQuery skips the irrelevant partitions first, so the search space is already smaller.

---

## Example: Optimized Search

```sql
-- 1. Build the index with Storing Clause
CREATE OR REPLACE VECTOR INDEX optimized_account_index 
ON `bqgraph_test.Account_Large`(embedding) 
STORING(id, account_type) 
OPTIONS(
    distance_type='COSINE', 
    index_type='IVF'
);

-- 2. Run the search with Pre-filtering
SELECT 
    base.id, 
    base.account_type, 
    distance
FROM VECTOR_SEARCH(
    TABLE `bqgraph_test.Account_Large`,
    'embedding',
    (SELECT [0.5, 0.5, 0.5]),
    top_k => 10,
    distance_type => 'COSINE'
)
WHERE base.account_type = 'Checking';
```

---

## How to Prove It

To see the difference, you need to look at the **Query Plan** and the **Job Metrics**. 

### 1. Check the Metrics
Run this query to see how much compute and data you're actually using:

```sql
SELECT 
    job_id,
    total_slot_ms, 
    total_bytes_processed,
    query
FROM `region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`
WHERE query LIKE '%Account_Large%'
ORDER BY creation_time DESC
LIMIT 5;
```

### 2. What the metrics mean
**Vector Indexes optimize Compute (Slot MS) and Latency, not Data Scanned.** 

*   **Total Slot MS (The massive win):** This is your compute time. A brute-force search forces BigQuery to execute dense mathematical equations (cosine similarity) on every single row. With an index, BigQuery uses pre-calculated clusters to skip the math on 99% of the rows. This number will drop drastically.
*   **Total Bytes Processed (The catch):** You might actually see this number go **UP** when using an index. Why? Because the index structure (clusters and centroids) is physically larger than the raw flat data. 
    *   *Where `STORING` saves you:* If you don't use the `STORING` clause (Join Elimination), BigQuery processes the larger index *AND* then joins back to read the base table, doubling your bytes scanned. By storing the columns you need inside the index, BigQuery never touches the base table, capping your scan costs.

### 3. Inspect the Plan
Run this in your CLI to see if the index was actually used:

```bash
# This one-liner finds your last search and outputs the plan automatically
bq show -j --location=US --format=prettyjson bqgraph-test-489809:$(bq query --use_legacy_sql=false --format=csv "SELECT job_id FROM \`bqgraph-test-489809.region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT\` WHERE query LIKE '%VECTOR_SEARCH%' AND query LIKE '%Account_Large%' ORDER BY creation_time DESC LIMIT 1" | tail -n 1)
```
Look for **`"indexUsageMode": "FULLY_USED"`** in the JSON output. If the index wasn't used, it will say `"UNUSED"` and give a `disable_reason`.

---
**Note:** BigQuery requires your base table to be at least **10MB** (about 500,000 rows of basic embeddings) before it will actually use a Vector Index. If the table is smaller, brute force is faster, so BigQuery intentionally leaves the index `TEMPORARILY DISABLED`.

When you add enough data, BigQuery still needs a few minutes to build it. Check the status:
```sql
SELECT index_status, coverage_percentage, disable_reason 
FROM `bqgraph-test-489809.bqgraph_test.INFORMATION_SCHEMA.VECTOR_INDEXES`
```
If `coverage_percentage` isn't 100%, you might still see a full scan.
