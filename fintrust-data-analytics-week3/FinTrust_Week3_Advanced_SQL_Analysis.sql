/* ============================================================================
   FinTrust Week 3 — Advanced SQL Business Analysis
   Data Analytics Track | AnalystLab Africa Experience Lab
   Builds on FinTrust_Week2_SQL_Analysis.sql (8 queries) with 8 NEW advanced
   queries using window functions, CTEs, subqueries and CASE logic.
   Tested in: SQLite (portable to MySQL / PostgreSQL / DuckDB)
   ============================================================================ */


/* ----------------------------------------------------------------------------
   AQ1. Rank customers within their own segment by total spend
        (Window function: RANK() ... PARTITION BY)
   ---------------------------------------------------------------------------- */
WITH customer_totals AS (
    SELECT t.Customer_ID, c.Customer_Segment, SUM(t.Amount_NGN) AS total_value
    FROM transactions t JOIN customers c ON t.Customer_ID = c.Customer_ID
    GROUP BY t.Customer_ID
)
SELECT Customer_Segment, Customer_ID, total_value,
       RANK() OVER (PARTITION BY Customer_Segment ORDER BY total_value DESC) AS segment_rank
FROM customer_totals
ORDER BY Customer_Segment, segment_rank;

/* RESULT (top of Everyday segment shown):
   Everyday  FT-C01075  1,713,942.51  rank 1
   Everyday  FT-C00357  1,713,516.28  rank 2
   Everyday  FT-C00816  1,611,209.24  rank 3   ...

   INTERPRETATION:
   This directly extends the Week 2 "top 5 customers" finding by ranking WITHIN
   each segment rather than across the whole customer base. This is the query a
   relationship manager would actually use \u2014 "who are my top 10 Premium
   customers" \u2014 rather than a single global top-5 list that happened to be
   dominated by Everyday-segment customers. */


/* ----------------------------------------------------------------------------
   AQ2. Month-over-month transaction value trend with running total
        (Window functions: SUM() OVER, LAG())
   ---------------------------------------------------------------------------- */
WITH monthly AS (
    SELECT strftime('%Y-%m', Transaction_DateTime) AS month,
           SUM(Amount_NGN) AS month_value, COUNT(*) AS month_count
    FROM transactions
    GROUP BY month
)
SELECT month, month_count, ROUND(month_value,2) AS month_value,
       ROUND(SUM(month_value) OVER (ORDER BY month), 2) AS running_total,
       ROUND(month_value - LAG(month_value) OVER (ORDER BY month), 2) AS change_vs_prev_month
FROM monthly
ORDER BY month;

/* RESULT:
   2026-01  4,133 txns  \u20a6188,489,434.69  running: \u20a6188.5m   change: n/a
   2026-02  3,734 txns  \u20a6175,786,896.99  running: \u20a6364.3m   change: -\u20a612.7m
   2026-03  4,133 txns  \u20a6196,201,023.17  running: \u20a6560.5m   change: +\u20a620.4m

   INTERPRETATION:
   This validates and deepens the Week 2 "stable daily volume" finding \u2014 at
   the monthly level, February dipped (-\u20a612.7m) before March recovered and
   exceeded January (+\u20a620.4m). The dip is worth flagging to FinTrust as a
   question (shorter month, or a genuine seasonal effect?) rather than treating
   all three months as interchangeable, as the Week 2 "no strong trend" framing
   implied. */


/* ----------------------------------------------------------------------------
   AQ3. Which customer segments have an ABOVE-AVERAGE risk review rate?
        (Subquery in HAVING clause + CASE)
   ---------------------------------------------------------------------------- */
SELECT c.Customer_Segment, COUNT(*) AS txn_count,
       ROUND(100.0*SUM(CASE WHEN t.Risk_Review_Flag='Yes' THEN 1 ELSE 0 END)/COUNT(*), 2) AS segment_risk_rate
FROM transactions t JOIN customers c ON t.Customer_ID = c.Customer_ID
GROUP BY c.Customer_Segment
HAVING segment_risk_rate > (
    SELECT 100.0*SUM(CASE WHEN Risk_Review_Flag='Yes' THEN 1 ELSE 0 END)/COUNT(*) FROM transactions
)
ORDER BY segment_risk_rate DESC;

/* RESULT:
   Premium  2,361 txns  20.33% risk rate
   Student  2,289 txns  19.75% risk rate
   (overall average: 19.60%; Everyday and SME fall below this line)

   INTERPRETATION:
   This is a genuinely new finding not visible in Week 2: Premium customers \u2014
   who likely transact in higher amounts \u2014 and Student customers \u2014 a
   demographically distinct group \u2014 both sit above the average risk-review
   rate, for probably different underlying reasons (transaction size vs.
   account-newness). Worth separate investigation per segment rather than
   treating "risk" as one undifferentiated pool. */


/* ----------------------------------------------------------------------------
   AQ4. What share of total transaction VALUE comes from the highest-value
        transactions? (CTE + NTILE window function — decile analysis)
   ---------------------------------------------------------------------------- */
WITH ranked AS (
    SELECT Amount_NGN, NTILE(10) OVER (ORDER BY Amount_NGN DESC) AS decile
    FROM transactions
)
SELECT decile, COUNT(*) AS txn_count, ROUND(SUM(Amount_NGN), 2) AS total_value,
       ROUND(100.0*SUM(Amount_NGN) / (SELECT SUM(Amount_NGN) FROM transactions), 2) AS pct_of_total_value
FROM ranked
GROUP BY decile
ORDER BY decile;

/* RESULT:
   Decile 1 (top 10% by value):  1,200 txns  \u20a6314.7m  = 56.15% of ALL transaction value
   Decile 2:                     1,200 txns  \u20a6119.1m  = 21.25%
   Deciles 3-10 combined:                              = 22.60%

   INTERPRETATION:
   This is the single most important new finding in Week 3: just 10% of
   transactions account for 56% of FinTrust's total transaction value. This
   reframes several Week 2 recommendations \u2014 reliability and risk-review
   investment aimed at "all transactions equally" is far less efficient than
   investment specifically targeted at this top decile, which carries more
   than half the platform's financial exposure. */


/* ----------------------------------------------------------------------------
   AQ5. Customer transaction-frequency tiers (CTE + CASE)
   ---------------------------------------------------------------------------- */
WITH freq AS (
    SELECT Customer_ID, COUNT(*) AS txn_count FROM transactions GROUP BY Customer_ID
)
SELECT
    CASE WHEN txn_count <= 4 THEN '1-4 (Low)'
         WHEN txn_count <= 9 THEN '5-9 (Medium)'
         ELSE '10+ (High)' END AS frequency_tier,
    COUNT(*) AS num_customers, ROUND(AVG(txn_count), 2) AS avg_txns_in_tier
FROM freq
GROUP BY frequency_tier
ORDER BY avg_txns_in_tier;

/* RESULT:
   1-4  (Low):     157 customers   avg 3.48 txns
   5-9  (Medium):  918 customers   avg 7.13 txns
   10+  (High):    425 customers   avg 11.54 txns

   INTERPRETATION:
   61% of customers (918 of 1,500) fall in the "Medium" frequency tier. The 157
   Low-frequency customers (10.5% of the base) are a natural re-engagement
   target \u2014 distinct from "Dormant" Account_Status in Week 2, since a
   customer can be Active but still transact rarely. */


/* ----------------------------------------------------------------------------
   AQ6. Share of transaction VALUE lost to Failed/Reversed status, by channel
        (CASE-based conditional aggregation)
   ---------------------------------------------------------------------------- */
SELECT Channel,
       ROUND(SUM(CASE WHEN Transaction_Status='Successful' THEN Amount_NGN ELSE 0 END), 2) AS successful_value,
       ROUND(SUM(CASE WHEN Transaction_Status IN ('Failed','Reversed') THEN Amount_NGN ELSE 0 END), 2) AS at_risk_value,
       ROUND(100.0*SUM(CASE WHEN Transaction_Status IN ('Failed','Reversed') THEN Amount_NGN ELSE 0 END)
             / SUM(Amount_NGN), 2) AS pct_value_at_risk
FROM transactions
GROUP BY Channel
ORDER BY pct_value_at_risk DESC;

/* RESULT:
   Web         8.24% of channel value lost to Failed/Reversed
   Mobile App  7.71%
   USSD        7.32%
   POS         7.15%
   ATM         4.75%   <- most reliable channel by value

   INTERPRETATION:
   This reframes the Week 2 "USSD is undervalued" finding in value terms, not
   just transaction-count terms: Web actually loses the highest PROPORTION of
   its value to failed/reversed transactions, not USSD. ATM is the most
   reliable channel by this measure. This is a more precise target for
   Operations than the Week 2 finding alone provided. */


/* ----------------------------------------------------------------------------
   AQ7. What share of customers have at least one "spike" transaction \u2014
        a single transaction over 3x their own average? (CTE + subquery)
   ---------------------------------------------------------------------------- */
WITH stats AS (
    SELECT Customer_ID, AVG(Amount_NGN) AS avg_amt, MAX(Amount_NGN) AS max_amt
    FROM transactions GROUP BY Customer_ID
)
SELECT COUNT(*) AS customers_with_spike,
       ROUND(100.0*COUNT(*) / (SELECT COUNT(DISTINCT Customer_ID) FROM transactions), 2) AS pct_of_customers
FROM stats
WHERE max_amt > 3 * avg_amt;

/* RESULT:
   1,097 of 1,500 customers (73.13%) have at least one transaction more than
   3x their own personal average.

   INTERPRETATION:
   At first glance this looks alarming, but at 73% of the ENTIRE customer base,
   an occasional large transaction is normal behaviour, not anomalous \u2014 this
   is a useful validation check showing that "transaction size relative to a
   customer's own average" is a poor standalone risk signal, since it would
   flag nearly three-quarters of customers. This directly informs the Data
   Science track: a per-customer outlier ratio alone is not a strong feature
   for the Risk_Review_Flag model without combining it with other signals. */


/* ----------------------------------------------------------------------------
   AQ8. International transaction risk rate over time, validating the Week 2
        "international = 2x risk rate" finding across all 3 months
        (CTE + GROUP BY on two dimensions)
   ---------------------------------------------------------------------------- */
WITH monthly_intl AS (
    SELECT strftime('%Y-%m', Transaction_DateTime) AS month, International_Transaction,
           COUNT(*) AS txn_count, SUM(CASE WHEN Risk_Review_Flag='Yes' THEN 1 ELSE 0 END) AS flagged
    FROM transactions
    GROUP BY month, International_Transaction
)
SELECT month, International_Transaction, txn_count, flagged,
       ROUND(100.0*flagged/txn_count, 2) AS risk_rate_pct
FROM monthly_intl
ORDER BY month, International_Transaction;

/* RESULT:
   2026-01  Domestic: 17.60%   International: 41.61%
   2026-02  Domestic: 19.65%   International: 36.17%
   2026-03  Domestic: 19.47%   International: 33.15%

   INTERPRETATION:
   This validates the Week 2 finding with monthly granularity: international
   risk rate is higher than domestic in EVERY month, confirming it is not a
   one-off artefact of aggregating the full quarter. Notably, the gap is
   narrowing over time (41.61% \u2192 33.15%) while domestic creeps up slightly
   (17.60% \u2192 19.47%) \u2014 worth monitoring whether these converge further in
   Week 4 data, which would change the risk-prioritisation recommendation. */
