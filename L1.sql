-- L1_status
CREATE OR REPLACE VIEW `de-kurz.L1.L1_status` AS 
SELECT 
  CAST(id_status AS INT64) AS product_status_id,
  LOWER(status_name) AS product_status_name,
  DATE(PARSE_DATE('%m/%d/%Y', date_update)) AS product_status_update_date
FROM `de-kurz.L0_google_sheet.L0_status`
WHERE id_status IS NOT NULL
  AND status_name IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY id_status) = 1
;

-- L1_branch 
CREATE OR REPLACE VIEW `de-kurz.L1.L1_branch` AS 
SELECT 
  CAST(id_branch AS int) AS branch_id, 
  branch_name
FROM `de-kurz.L0_google_sheet.L0_branch` 
WHERE id_branch IS NOT NULL AND id_branch != 'NULL'
;

-- L1_product
CREATE OR REPLACE VIEW `de-kurz.L1.L1_product` AS
SELECT 
   DISTINCT CAST(id_product AS INT64)  AS product_id
  ,name AS product_name
  ,is_vat_applicable
  ,type AS product_type
  ,category AS product_category
  ,DATE(PARSE_DATE('%m/%d/%Y', date_update)) AS product_update_date
FROM `L0_google_sheet.L0_all_products`
;

-- L1_invoice
CREATE OR REPLACE VIEW `de-kurz.L1.L1_invoice` AS 
SELECT
  id_invoice AS invoice_id
  ,id_invoice_old AS invoice_previous_id
  ,invoice_id_contract AS contract_id -- FK
  ,id_branch AS branch_id
  ,status AS invoice_status_id
  ,number AS invoice_number
  -- Invoce status. Invoice status < 100 have been issued. >= 100 - not issued
  ,IF(status < 100, TRUE, FALSE) AS flag_invoice_issued
  ,flag_paid_currier
  ,DATE(TIMESTAMP(date), "Europe/Prague") AS date_issue
  ,DATE(TIMESTAMP(scadent), "Europe/Prague") AS due_date
  ,DATE(TIMESTAMP(date_paid), "Europe/Prague") AS paid_date
  ,DATE(TIMESTAMP(start_date), "Europe/Prague") AS start_date
  ,DATE(TIMESTAMP(end_date), "Europe/Prague") AS end_date
  ,DATE(TIMESTAMP(date_insert), "Europe/Prague") AS insert_date
  ,DATE(TIMESTAMP(date_update), "Europe/Prague") AS update_date
  ,value AS amount_w_vat
  ,payed AS amount_paid_w_vat
  ,value_storno AS amount_storno_w_vat
  ,invoice_type AS invoice_type_id -- Invice_type: 1 - invoice, 3 - credit_note, 2 - return, 4 - other
  ,CASE 
    WHEN invoice_type = 1 THEN "invoice"
    WHEN invoice_type = 2 THEN "return"
    WHEN invoice_type = 3 THEN "credit_note"
    WHEN invoice_type = 4 THEN "other"
   END AS invoice_type
FROM `de-kurz.L0_accounting_system.invoices`
;

-- L1_product_purchase
CREATE OR REPLACE VIEW `de-kurz.L1.L1_product_purchase` AS
SELECT
  pp.id_package AS product_purchase_id
 ,pp.id_contract AS contract_id
 ,pp.id_package_template AS product_id
 ,DATETIME(pp.date_insert, "Europe/Prague") AS created_at_date
 ,DATETIME(TIMESTAMP(pp.start_date), "Europe/Prague") AS product_valid_from
 ,DATETIME(TIMESTAMP(pp.end_date), "Europe/Prague") AS product_valid_to
 ,pp.fee AS price_without_vat
 ,pp.date_update AS update_date
 ,SAFE_CAST(pp.package_status AS INT64) AS product_status_id
 ,s.product_status_name
 ,CASE 
    WHEN pp.measure_unit IN ('mesia','m?síce','m?si?1ce','měsice','mesiace','měsíce','mesice') THEN  'month'
    WHEN pp.measure_unit = "kus" THEN "item"
    WHEN pp.measure_unit = "den" THEN 'day'
    WHEN pp.measure_unit = "min" THEN 'minute'
    WHEN pp.measure_unit = '0' THEN NULL 
    ELSE pp.measure_unit 
  END AS measure_unit
 ,p.product_name
 ,p.product_type
 ,p.product_category
FROM `de-kurz.L0_crm.product_purchases` AS pp
LEFT JOIN `de-kurz.L1.L1_status` AS s ON pp.package_status = s.product_status_id
LEFT JOIN `de-kurz.L1.L1_product`AS p ON pp.id_package_template = p.product_id
;


-- L1_contract 
CREATE OR REPLACE VIEW `de-kurz.L1.L1_contract` AS 
SELECT 
   id_contract as contract_id
  ,id_branch as branch_id 
  ,DATETIME(date_contract_valid_from, "Europe/Prague") AS contract_valid_from
  ,DATETIME(TIMESTAMP(date_contract_valid_to), "Europe/Prague") AS contract_valid_to
  ,DATETIME(date_registered, "Europe/Prague") AS registered_date
  ,DATETIME(date_signed, "Europe/Prague") AS signed_date
  ,DATETIME(activation_process_date, "Europe/Prague") AS activation_process_date
  ,DATETIME(prolongation_date, "Europe/Prague") AS prolongation_date
  ,registration_end_reason 
  ,flag_prolongation 
  ,flag_send_inv_email as flag_sent_email 
  ,contract_status 
FROM `de-kurz.L0_crm.contracts`
;

--L1 invoice product purchase
CREATE OR REPLACE VIEW `de-kurz.L1.L1_invoice_product_purchase` AS 
SELECT 
  id_invoice AS invoice_id
 ,CAST (id_package AS INT) AS product_purchase_id
FROM `de-kurz.L0_accounting_system.invoices_load`
;
