# fintrust-data-analytics-Week1
Week 1 report: business understanding, data profiling, 8 KPIs, dashboard wireframe, Week 2–4 plan
## Week 2 — Analyse & Prepare

**Status:** Complete

Moved from Week 1 planning into hands-on analysis using the full FinTrust datasets 
(1,500 customers, 12,000 transactions).

### What's in this folder
- `FinTrust_Week2_DataQuality_Report.pdf` — data quality findings report
- `FinTrust_Week2_DataCleaning_Log.xlsx` — row-by-row record of every cleaning action taken
- `FinTrust_Week2_SQL_Analysis.sql` — 8 business questions answered in SQL, with interpretations
- `FinTrust_Week2_Data_Analysis.ipynb` — Python EDA with 5 visualisations
- `FinTrust_Week2_Analytics_Dashboard.pbix` — Power BI dashboard (KPI cards, trend, channel, risk and geographic views)
- `FinTrust_Week2_Documentation.docx` — full write-up: tools used, dashboard build notes, business insights, testing evidence, Week 2 summary

### Key findings
- Overall transaction success rate: **90.47%**
- USSD has the lowest transaction volume of any channel but the **highest average transaction value**
- International transactions are flagged for risk review at **~2x** the domestic rate (36.88% vs 18.88%)
- Lagos accounts for a large share of transaction activity by customer residence
- Several top-value customers are labelled "Everyday," not "Premium"

### Tools used
Microsoft Excel · SQLite · Python (Pandas, Matplotlib, Seaborn) · Power BI Desktop

---

## Week 3 — Develop & Integrate

**Status:** Complete

Built directly on Week 2: extended the SQL and Python analysis with more advanced techniques, 
expanded the dashboard, and — critically — went back and validated every major Week 2 finding 
against fresh evidence rather than assuming it was correct.

### What's in this folder
- `FinTrust_Week3_Advanced_SQL_Analysis.sql` — 8 additional queries using window functions, CTEs, subqueries and CASE logic
- `FinTrust_Week3_Advanced_Analysis.ipynb` — 5 additional analyses: weekly trend, Pareto/value-concentration, customer segmentation, comparative risk trend, correlation check
- `FinTrust_Week3_Analytics_Dashboard.pbix` — extended dashboard with trend analysis, customer analysis, and tested cross-filtering
- `FinTrust_Week3_Documentation.docx` — gap review, 5 validated findings, 5 recommendations, validation/refinement evidence, updated limitations, Week 3 summary

### Key findings
- **Caught and corrected a methodological error** from Week 2: the original "Lagos dominates transaction value" finding was based on customer home city, not actual transaction location — re-validated using the correct field, value is spread almost evenly across all 8 cities
- **Top 10% of transactions account for 56% of total transaction value** (decile/Pareto analysis)
- Refined the channel-reliability finding: **Web**, not USSD, has the highest share of value lost to failed/reversed transactions
- International risk rate remains higher than domestic in every month, though the gap is narrowing
- High-value customers exist within every customer segment, not just "Premium"

### Tools used
SQLite (window functions, CTEs) · Python (Pandas, Matplotlib, Seaborn) · Power BI Desktop
