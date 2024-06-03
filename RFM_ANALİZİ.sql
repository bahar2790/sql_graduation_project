WITH recency AS (
  WITH tablo AS (
    SELECT
      customer_id,
      MAX(invoicedate) AS last_invoice_date
    FROM
      rfm
    WHERE
      customer_id IS NOT NULL
      AND invoiceno NOT LIKE 'C%'
    GROUP BY 1
  )
  SELECT 
    customer_id,
    last_invoice_date,
    '2011-12-09'::date - last_invoice_date::date AS recency
  FROM 
    tablo
),
frequency AS (
  SELECT 
    customer_id,
    COUNT(invoiceno) AS frequency
  FROM 
    rfm
  WHERE 
    customer_id IS NOT NULL
    AND invoiceno NOT LIKE 'C%'
  GROUP BY 
    customer_id
),
monetary AS (
  SELECT
    customer_id,
    SUM(quantity * unitprice) AS monetary
  FROM 
    rfm
  WHERE 
    customer_id IS NOT NULL 
    AND invoiceno NOT LIKE 'C%'
  GROUP BY 1
),
scores AS (
  SELECT 
    r.customer_id,
    recency,
    NTILE(5) OVER (ORDER BY recency DESC) AS recency_score,
    frequency,
    CASE WHEN frequency BETWEEN 1 AND 4 THEN frequency ELSE 5 END AS frequency_score,
    monetary,
    NTILE(5) OVER (ORDER BY monetary ) AS monetary_score
  FROM 
    recency r
    JOIN frequency f ON r.customer_id = f.customer_id
    JOIN monetary m ON m.customer_id = r.customer_id
)
SELECT 
  customer_id,
  recency_score || '-' || frequency_score || '-' || monetary_score AS RFM_Score
FROM 
  scores;
