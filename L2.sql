--L2 contract
CREATE OR REPLACE VIEW `de-kurz.L2.L2_contract` AS
SELECT
  contract_id
 ,branch_id
 ,contract_valid_from
 ,contract_valid_to
 ,registered_date
 ,signed_date
 ,registration_end_reason
 ,prolongation_date
 ,flag_prolongation 
 ,contract_status
 ,activation_process_date
 ,flag_sent_email 
FROM `de-kurz.L1.L1_contract`
WHERE registered_date IS NOT NULL
;
--L2 invoice
CREATE OR REPLACE VIEW `L2.L2_invoice` AS
SELECT
  invoice_id
 ,invoice_previous_id
 ,contract_id
 ,invoice_type
 ,invoice_status_id
 ,CASE WHEN amount_w_vat < 0 THEN 0 ELSE amount_w_vat END AS amount_with_vat
 ,amount_storno_w_vat AS return_with_vat
 ,CASE WHEN amount_w_vat < 0 THEN 0 ELSE amount_w_vat/1.2 END AS amount_without_vat
 ,paid_date
 ,date_issue
 ,due_date
 ,start_date
 ,end_date
 ,insert_date
 ,update_date
 ,flag_invoice_issued
 ,ROW_NUMBER() OVER (PARTITION BY contract_id ORDER BY date_issue) AS invoice_order -- kolikata faktura v poradi
FROM `L1.L1_invoice`
WHERE invoice_type = 'invoice'
AND flag_invoice_issued
;
--L2 product purchase
CREATE OR REPLACE VIEW `L2.L2_product_purchase` AS
SELECT
  product_id
 ,contract_id
 ,product_purchase_id
 ,product_category
 ,product_status_name
 ,price_without_vat
 ,CASE 
   WHEN product_valid_from IS NOT NULL AND product_valid_to IS NULL THEN 1 
   ELSE 0 
  END AS flag_unlimited_product --- unlimited from
 ,product_valid_to
 ,product_valid_from
 ,measure_unit
 ,product_type
 ,product_name
FROM `L1.L1_product_purchase` 
WHERE product_category IN ('rent','product')
  AND product_status_name IS NOT NULL
  AND product_status_name NOT LIKE 'canceled%'
  AND product_status_name NOT LIKE 'disconnected%'

;
-- L2 product
CREATE OR REPLACE VIEW `L2.L2_product` AS
SELECT
  product_id
 ,product_name
 ,product_type
 ,product_category
FROM `L1.L1_product`
;
-- L2 branch
CREATE OR REPLACE VIEW `L2.L2_branch` AS
SELECT 
  branch_id
 ,branch_name
FROM `L1.L1_branch`
WHERE branch_name != 'unknown'
;

--L2 invoice items
CREATE OR REPLACE VIEW `L2.L2_invoice_items` AS
SELECT 
  ii.invoice_id
 ,ii.product_purchase_id
 ,pp.price_without_vat AS product_price_without_vat
FROM `L1.L1_invoice_product_purchase` AS ii
JOIN `L2.L2_product_purchase` AS pp ON pp.product_purchase_id = ii.product_purchase_id
JOIN `L2.L2_invoice` i ON ii.invoice_id = i.invoice_id
;


