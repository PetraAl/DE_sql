-- L3 data mart for marketing report
-- metrics for specific reporting purpose, reporting and data mart documentation, requirements and needs

-- Business questions:
---------------------------
-- which customers and when leave? value of customer? upsell/upgrade
-- one contract = one customer
-- package count per contract
-- contract cancelled or registration cancelled
-- best package, revenue
-- best package by year

-- Technical requirements (with data analyst):
---------------------------
-- visualizations requirements
-- granularity
-- dimensions and metrics

-- max 5 tables
-- limited number of dimensions and metrics
-- metrics to calculate: contract duration (yrs), not include null, contract_valid_from IS NOT NULL, contract_valid_to IS NOT NULL, filter ou cases where  contract_valid_to < contract_valid_from, 
-- total paid amount in usd per invoice (amount_with_vat - return_with_vat)

-- L3 contract
CREATE OR REPLACE VIEW `de-kurz.L3.L3_contract` AS
SELECT
  contract_id
 ,branch_id
 ,contract_valid_from
 ,contract_valid_to
 ,CASE 
   WHEN DATE_DIFF(contract_valid_to, contract_valid_from, DAY) <= 183 THEN 'less then half a year'
   WHEN DATE_DIFF(contract_valid_to, contract_valid_from, DAY) <= 365 THEN 'one year'
   WHEN DATE_DIFF(contract_valid_to, contract_valid_from, DAY) <= 548 THEN 'less than a year and half'
   WHEN DATE_DIFF(contract_valid_to, contract_valid_from, DAY) <= 730 THEN 'two years and more'
   ELSE 'more than 2'
 END AS contract_duration --(in yrs)
 ,EXTRACT(YEAR FROM registered_date) AS contract_start_year
 ,registration_end_reason
 ,prolongation_date
 ,flag_prolongation 
 ,contract_status
FROM `de-kurz.L2.L2_contract`
WHERE contract_valid_from IS NOT NULL 
  AND contract_valid_to IS NOT NULL
;

-- L3 invoice
CREATE OR REPLACE VIEW `L3.L3_invoice` AS
SELECT
  DISTINCT i.invoice_id
 ,i.contract_id
 ,i.amount_with_vat
 ,i.return_with_vat
 ,i.amount_with_vat - return_with_vat AS total_paid_usd
 ,i.paid_date
FROM `L2.L2_invoice` AS i
JOIN `L2.L2_invoice_items` AS ii ON ii.invoice_id = i.invoice_id
;

-- L3 invoice items
CREATE OR REPLACE VIEW `L3.L3_invoice_items` AS
SELECT
   invoice_id
  ,product_purchase_id
  ,product_price_without_vat 
FROM `L2.L2_invoice_items`
;

-- L3 product
CREATE OR REPLACE VIEW `L3.L3_product_purchase` AS
SELECT
  product_purchase_id
 ,contract_id
 ,product_id
 ,flag_unlimited_product
 ,product_valid_to
 ,product_valid_from
 ,measure_unit
 ,product_type
 ,product_name
FROM `L2.L2_product_purchase` 
;

-- L3 branch
CREATE OR REPLACE VIEW `L3.L3_branch` AS
SELECT 
  branch_id
 ,branch_name
FROM `L2.L2_branch`
;
