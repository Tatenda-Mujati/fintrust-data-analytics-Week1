/* ============================================================================
   FinTrust Week 4 — FINAL SQL ANALYSIS
   Data Analytics Track | AnalystLab Africa Experience Lab

   Tables : customers  (FinTrust_Customer_Data, 1,500 rows)
            transactions (FinTrust_Transaction_Data, 12,000 rows)
   Join   : transactions.Customer_ID = customers.Customer_ID
   Engine : SQLite (every query was executed and the results below are the
            actual output). strftime()/date() are SQLite functions; in
            MySQL use DATE_FORMAT()/DATE(), in PostgreSQL use TO_CHAR()/::date.

   These 9 queries are the final, most decision-relevant analyses selected
   from the 24 written across Weeks 2-4. Several Week 2/3 queries were
   re-examined this week; where a conclusion changed, the interpretation
   below says so explicitly (see also the Validation section of the report).
   ============================================================================ */


/* ----------------------------------------------------------------------------
   FQ1. Headline KPIs (aggregations + CASE)
   Reconciled against pandas and the Power BI KPI cards - all three match.
   ---------------------------------------------------------------------------- */
SELECT (SELECT COUNT(*) FROM customers) AS total_customers,
       COUNT(*) AS total_transactions,
       ROUND(SUM(Amount_NGN),2) AS total_value_ngn,
       ROUND(AVG(Amount_NGN),2) AS avg_value_ngn,
       ROUND(100.0*SUM(CASE WHEN Transaction_Status='Successful' THEN 1 ELSE 0 END)/COUNT(*),2) AS success_rate_pct,
       ROUND(100.0*SUM(CASE WHEN Risk_Review_Flag='Yes' THEN 1 ELSE 0 END)/COUNT(*),2) AS risk_review_rate_pct
FROM transactions;

/* RESULT: 1,500 customers | 12,000 transactions | NGN 560,477,354.85 total |
           NGN 46,706.45 average | 90.47% success | 19.60% risk-review rate
   MEANING: these are the six KPI cards on the dashboard. The average is pulled
   up by a small number of very large transactions (median is only ~NGN 10,000),
   so "average transaction value" should always be read alongside the median. */


/* ----------------------------------------------------------------------------
   FQ2. Risk-review rate by transaction type, ranked (CTE + RANK window)
   ---------------------------------------------------------------------------- */
WITH by_type AS (
  SELECT Transaction_Type, COUNT(*) AS txns,
         SUM(CASE WHEN Risk_Review_Flag='Yes' THEN 1 ELSE 0 END) AS flagged
  FROM transactions GROUP BY Transaction_Type)
SELECT RANK() OVER (ORDER BY 1.0*flagged/txns DESC) AS risk_rank, Transaction_Type, txns, flagged,
       ROUND(100.0*flagged/txns,2) AS risk_rate_pct,
       ROUND(100.0*flagged/txns - (SELECT 100.0*SUM(flagged)/SUM(txns) FROM by_type),2) AS pts_vs_overall
FROM by_type ORDER BY risk_rank;

/* RESULT: 1 Transfer 28.49% (+8.89 pts) | 2 Cash Withdrawal 25.31% (+5.71) |
           3 Deposit 16.19% | 4 Airtime/Data 15.19% | 5 Card Purchase 13.02% |
           6 Bill Payment 12.81%
   MEANING: transaction type is the strongest single association with the
   risk-review label (chi-square p < 1e-70, Cramer's V = 0.17 in the Python
   validation). Transfers and Cash Withdrawals sit 6-9 points above the overall
   rate; the other four types sit below it. VALIDATED in Week 4.
   NOTE: Risk_Review_Flag is a synthetic educational label, not a fraud finding. */


/* ----------------------------------------------------------------------------
   FQ3. Does the international effect survive within each transaction type?
   (conditional aggregation - checks the Week 2 finding is not a type-mix artefact)
   ---------------------------------------------------------------------------- */
SELECT Transaction_Type,
  ROUND(100.0*SUM(CASE WHEN International_Transaction='No'  AND Risk_Review_Flag='Yes' THEN 1 ELSE 0 END)
        / SUM(CASE WHEN International_Transaction='No' THEN 1 ELSE 0 END),1) AS domestic_risk_pct,
  ROUND(100.0*SUM(CASE WHEN International_Transaction='Yes' AND Risk_Review_Flag='Yes' THEN 1 ELSE 0 END)
        / SUM(CASE WHEN International_Transaction='Yes' THEN 1 ELSE 0 END),1) AS international_risk_pct,
  SUM(CASE WHEN International_Transaction='Yes' THEN 1 ELSE 0 END) AS intl_txns
FROM transactions GROUP BY Transaction_Type ORDER BY international_risk_pct DESC;

/* RESULT (domestic -> international): Transfer 27.9 -> 42.0 | Cash Withdrawal 24.9 -> 40.5 |
           Deposit 15.2 -> 38.6 | Card Purchase 12.1 -> 35.2 | Airtime/Data 14.4 -> 32.0 |
           Bill Payment 12.3 -> 26.8
   MEANING: international transactions are flagged more often in EVERY transaction
   type (+14 to +23 points), and they make up ~4% of each type, so the effect is
   independent of type mix. Overall: 36.9% vs 18.9% (chi-square p < 1e-21).
   VALIDATED. What did NOT validate: the Week 3 claim that the international gap
   is "narrowing" over the quarter - Jan vs Mar difference is not statistically
   significant (two-proportion z-test p = 0.107; monthly 95% intervals overlap). */


/* ----------------------------------------------------------------------------
   FQ4. Value concentration by transaction-value decile (NTILE + cumulative window)
   ---------------------------------------------------------------------------- */
WITH ranked AS (SELECT Amount_NGN, NTILE(10) OVER (ORDER BY Amount_NGN DESC) AS decile FROM transactions)
SELECT decile, COUNT(*) AS txns, ROUND(SUM(Amount_NGN),0) AS value_ngn,
       ROUND(100.0*SUM(Amount_NGN)/(SELECT SUM(Amount_NGN) FROM transactions),2) AS pct_of_value,
       ROUND(SUM(100.0*SUM(Amount_NGN)/(SELECT SUM(Amount_NGN) FROM transactions)) OVER (ORDER BY decile),2) AS cumulative_pct
FROM ranked GROUP BY decile ORDER BY decile;

/* RESULT: decile 1 = 56.15% of value | deciles 1-2 = 77.41% | deciles 1-5 = 96.62% |
           the bottom 50% of transactions together carry only 3.38% of value
   MEANING: value is extremely concentrated (Gini coefficient 0.735; bootstrap 95%
   interval for the top-10% share = 55.2%-57.0%, so the figure is stable). The top
   decile is made up of Transfers (51%), Deposits (26%), Cash Withdrawals (13%) and
   Card Purchases (10%). VALIDATED. Operationally: monitoring effort weighted by
   value covers most of the money far more efficiently than equal weighting. */


/* ----------------------------------------------------------------------------
   FQ5. Risk-review rate by transaction-amount quintile (NTILE)
   ---------------------------------------------------------------------------- */
WITH amt AS (SELECT NTILE(5) OVER (ORDER BY Amount_NGN) AS quintile, Risk_Review_Flag, Amount_NGN FROM transactions)
SELECT quintile, COUNT(*) AS txns, ROUND(MIN(Amount_NGN),0) AS min_amt, ROUND(MAX(Amount_NGN),0) AS max_amt,
       ROUND(100.0*SUM(CASE WHEN Risk_Review_Flag='Yes' THEN 1 ELSE 0 END)/COUNT(*),2) AS risk_rate_pct
FROM amt GROUP BY quintile ORDER BY quintile;

/* RESULT: Q1 17.83% | Q2 17.58% | Q3 17.46% | Q4 18.38% | Q5 (NGN 68,276+) 26.75%
   MEANING: NEW finding. Risk-review is flat (~17.5-18.4%) across the lower four
   quintiles and jumps ~8-9 points only in the top 20% by amount - a threshold
   effect rather than a smooth increase. Together with FQ4 this means the largest
   transactions are both the most valuable AND the most frequently flagged. */


/* ----------------------------------------------------------------------------
   FQ6. Monthly trend normalised per active day (CTE + LAG window)
   CORRECTS the Week 3 "February dip" finding.
   ---------------------------------------------------------------------------- */
WITH monthly AS (
  SELECT strftime('%Y-%m',Transaction_DateTime) AS month, COUNT(*) AS txns, SUM(Amount_NGN) AS value_ngn,
         COUNT(DISTINCT date(Transaction_DateTime)) AS active_days
  FROM transactions GROUP BY month)
SELECT month, active_days, txns, ROUND(value_ngn,0) AS value_ngn,
       ROUND(1.0*txns/active_days,1) AS txns_per_day, ROUND(value_ngn/active_days,0) AS value_per_day,
       ROUND(100.0*(value_ngn - LAG(value_ngn) OVER (ORDER BY month))/LAG(value_ngn) OVER (ORDER BY month),2) AS raw_value_change_pct,
       ROUND(100.0*((value_ngn/active_days) - LAG(value_ngn/active_days) OVER (ORDER BY month))
             /LAG(value_ngn/active_days) OVER (ORDER BY month),2) AS per_day_change_pct
FROM monthly ORDER BY month;

/* RESULT: Jan 31 days 133.3 txns/day NGN 6.08m/day |
           Feb 28 days 133.4 txns/day NGN 6.28m/day (raw -6.74%, per-day +3.25%) |
           Mar 31 days 133.3 txns/day NGN 6.33m/day (raw +11.61%, per-day +0.81%)
   MEANING: the "February dip" reported in Week 3 was a calendar artefact - February
   has 3 fewer days. Per day, volume is identical (133 transactions) and value is
   slightly HIGHER than January. Conclusion REVISED: no real dip; always compare
   months on a per-day basis. (Daily volume varies by only +/-0.5 around 133, and
   hourly volume is exactly 500 in every hour, which also tells us the time
   dimension in this synthetic dataset is almost perfectly uniform.) */


/* ----------------------------------------------------------------------------
   FQ7. Failed/Reversed rate and value-at-risk by channel (conditional aggregation)
   ---------------------------------------------------------------------------- */
SELECT Channel, COUNT(*) AS txns,
       ROUND(100.0*SUM(CASE WHEN Transaction_Status IN ('Failed','Reversed') THEN 1 ELSE 0 END)/COUNT(*),2) AS failed_reversed_rate_pct,
       ROUND(100.0*SUM(CASE WHEN Transaction_Status IN ('Failed','Reversed') THEN Amount_NGN ELSE 0 END)/SUM(Amount_NGN),2) AS value_at_risk_pct,
       ROUND(AVG(Amount_NGN),0) AS avg_value
FROM transactions GROUP BY Channel ORDER BY failed_reversed_rate_pct DESC;

/* RESULT: USSD 8.66% / 7.32% | Mobile App 8.64% / 7.71% | POS 7.73% / 7.15% |
           Web 7.12% / 8.24% | ATM 6.87% / 4.75%   (failure rate / value-at-risk)
   MEANING: the channel ranking changes depending on the metric (USSD worst by
   count, Web worst by value), and a chi-square test on failure rate by channel
   gives p = 0.07 with overlapping bootstrap intervals - so there is NO
   statistically clear "worst channel". Week 3's "Web has the highest value-at-risk"
   is REVISED to: failures are spread fairly evenly (7.97% of transactions,
   NGN 40.45m = 7.22% of value, platform-wide); ATM looks somewhat better but only
   borderline (ATM vs rest p = 0.074). Also: the Week 2 claim that USSD has the
   "highest average value" is not supported - average value does not differ by
   channel (ANOVA p = 0.39, Kruskal-Wallis p = 0.75). */


/* ----------------------------------------------------------------------------
   FQ8. Customer value and frequency by segment (LEFT JOIN + CTE + window)
   ---------------------------------------------------------------------------- */
WITH cust AS (
  SELECT c.Customer_ID, c.Customer_Segment, COALESCE(SUM(t.Amount_NGN),0) AS total_value, COUNT(t.Transaction_ID) AS txns
  FROM customers c LEFT JOIN transactions t ON c.Customer_ID=t.Customer_ID GROUP BY c.Customer_ID)
SELECT Customer_Segment, COUNT(*) AS customers, ROUND(AVG(txns),2) AS avg_txns,
       ROUND(AVG(total_value),0) AS avg_value_per_customer,
       ROUND(AVG(AVG(total_value)) OVER (),0) AS avg_of_segment_avgs
FROM cust GROUP BY Customer_Segment ORDER BY avg_value_per_customer DESC;

/* RESULT: SME 216 customers NGN 387,923 | Student 278 NGN 386,604 |
           Everyday 711 NGN 367,734 | Premium 295 NGN 365,258   (avg txns 7.9-8.2 each)
   MEANING: customer segments are essentially indistinguishable on value, activity
   and risk: the spread in average value is ~6% and not significant (Kruskal-Wallis
   p = 0.46); risk rates are 19.3%-20.3% (chi-square p = 0.75); engagement scores
   are 66.7-68.4 (p = 0.54). This REPLACES two earlier claims: Week 3's "Premium
   and Student have above-average risk" and the Week 2 "top customers aren't
   Premium" (3 of the top 5 being Everyday is expected - Everyday is 47% of
   customers). The finding that matters: the current segment labels do not
   separate customers by behaviour or value. */


/* ----------------------------------------------------------------------------
   FQ9. Customer home city vs transaction location (3 CTEs + JOINs)
   ---------------------------------------------------------------------------- */
WITH cust_share AS (SELECT City AS place, 100.0*COUNT(*)/(SELECT COUNT(*) FROM customers) AS pct_customers FROM customers GROUP BY City),
     loc_share AS (SELECT Location AS place, 100.0*SUM(Amount_NGN)/(SELECT SUM(Amount_NGN) FROM transactions WHERE Location IS NOT NULL) AS pct_value_by_location
                   FROM transactions WHERE Location IS NOT NULL GROUP BY Location),
     home_val AS (SELECT c.City AS place, 100.0*SUM(t.Amount_NGN)/(SELECT SUM(Amount_NGN) FROM transactions) AS pct_value_by_home_city
                  FROM transactions t JOIN customers c ON t.Customer_ID=c.Customer_ID GROUP BY c.City)
SELECT cs.place, ROUND(cs.pct_customers,1) AS pct_of_customers, ROUND(hv.pct_value_by_home_city,1) AS pct_value_by_home_city,
       ROUND(ls.pct_value_by_location,1) AS pct_value_by_txn_location
FROM cust_share cs JOIN home_val hv ON cs.place=hv.place JOIN loc_share ls ON cs.place=ls.place ORDER BY pct_of_customers DESC;

/* RESULT (customers % | value by home city % | value by transaction location %):
           Lagos 32.5 | 33.9 | 11.5      Abuja 14.9 | 14.9 | 11.2
           Port Harcourt 11.5 | 11.4 | 12.8     Kano 10.6 | 10.8 | 13.4
           Ibadan 9.9 | 10.0 | 14.6     Enugu 7.2 | 7.1 | 12.4
           Kaduna 6.9 | 6.4 | 12.7      Benin City 6.6 | 5.5 | 11.4
   MEANING: the Week 3 correction is CONFIRMED and sharpened. Lagos holds 32.5% of
   customers and 33.9% of value by home city (note: the Week 2/3 documents
   quoted 36.1% - an arithmetic error, corrected here). That mirrors customer
   headcount, so it is a customer-base fact, not a spending-intensity fact. By
   transaction location, value is spread evenly (11.1%-14.5% per city; uniformity
   test p = 0.34) and location is statistically unrelated to home city (chi-square
   p = 0.67; the two fields agree 12.7% of the time vs 12.4% expected by pure
   chance). Use City for customer-base questions and Location for where
   transactions are recorded - and ask the data owner what Location means. */
