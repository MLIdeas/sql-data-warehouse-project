USE DataWarehouse;
GO

/* ============================================================
   QUALITY CHECKS - SILVER LAYER
   Purpose:
   - Validate cleaned and standardized data in the Silver layer
   - Check duplicates, NULLs, invalid dates, invalid values,
     referential issues, and business-rule violations
   ============================================================ */


-- ============================================================
-- 1. CHECK ROW COUNTS
-- ============================================================

SELECT 'silver.crm_cust_info' AS table_name, COUNT(*) AS row_count FROM silver.crm_cust_info
UNION ALL
SELECT 'silver.crm_prd_info', COUNT(*) FROM silver.crm_prd_info
UNION ALL
SELECT 'silver.crm_sales_details', COUNT(*) FROM silver.crm_sales_details
UNION ALL
SELECT 'silver.erp_cust_az12', COUNT(*) FROM silver.erp_cust_az12
UNION ALL
SELECT 'silver.erp_loc_a101', COUNT(*) FROM silver.erp_loc_a101
UNION ALL
SELECT 'silver.erp_px_cat_g1v2', COUNT(*) FROM silver.erp_px_cat_g1v2;
GO


/* ============================================================
   CHECKS FOR silver.crm_cust_info
   ============================================================ */

-- Check for NULL or duplicate customer IDs
-- Expected result: no rows
SELECT 
    cst_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING cst_id IS NULL OR COUNT(*) > 1;
GO


-- Check for unwanted spaces in customer first name
-- Expected result: no rows
SELECT *
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);
GO


-- Check for unwanted spaces in customer last name
-- Expected result: no rows
SELECT *
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);
GO


-- Check marital status standardization
-- Expected values: Single, Married, n/a
SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info;
GO


-- Check gender standardization
-- Expected values: Male, Female, n/a
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;
GO


-- Check for invalid marital status values
-- Expected result: no rows
SELECT *
FROM silver.crm_cust_info
WHERE cst_marital_status NOT IN ('Single', 'Married', 'n/a');
GO


-- Check for invalid gender values
-- Expected result: no rows
SELECT *
FROM silver.crm_cust_info
WHERE cst_gndr NOT IN ('Male', 'Female', 'n/a');
GO


-- Check customer create dates
-- Expected result: review rows if any future dates appear
SELECT *
FROM silver.crm_cust_info
WHERE cst_create_date > GETDATE();
GO



/* ============================================================
   CHECKS FOR silver.crm_prd_info
   ============================================================ */

-- Check for NULL or duplicate product IDs
-- Expected result: no rows
SELECT 
    prd_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING prd_id IS NULL OR COUNT(*) > 1;
GO


-- Check for unwanted spaces in product name
-- Expected result: no rows
SELECT *
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);
GO


-- Check for NULL or negative product cost
-- Expected result: no rows
SELECT *
FROM silver.crm_prd_info
WHERE prd_cost IS NULL 
   OR prd_cost < 0;
GO


-- Check product line standardization
-- Expected values: Mountain, Road, Other Sales, Touring, n/a
SELECT DISTINCT prd_line
FROM silver.crm_prd_info;
GO


-- Check for invalid product line values
-- Expected result: no rows
SELECT *
FROM silver.crm_prd_info
WHERE prd_line NOT IN ('Mountain', 'Road', 'Other Sales', 'Touring', 'n/a');
GO


-- Check invalid product dates
-- Product end date should not be before start date
-- Expected result: no rows
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;
GO


-- Check product category ID against ERP category table
-- Expected result: no rows
SELECT *
FROM silver.crm_prd_info p
WHERE NOT EXISTS (
    SELECT 1
    FROM silver.erp_px_cat_g1v2 c
    WHERE p.cat_id = c.id
);
GO


-- Check product keys that exist in sales but not in product info
-- Expected result: no rows
SELECT DISTINCT 
    s.sls_prd_key
FROM silver.crm_sales_details s
LEFT JOIN silver.crm_prd_info p
    ON s.sls_prd_key = p.prd_key
WHERE p.prd_key IS NULL;
GO



/* ============================================================
   CHECKS FOR silver.crm_sales_details
   ============================================================ */

-- Check for NULL order numbers
-- Expected result: no rows
SELECT *
FROM silver.crm_sales_details
WHERE sls_ord_num IS NULL 
   OR TRIM(sls_ord_num) = '';
GO


-- Check for NULL product keys
-- Expected result: no rows
SELECT *
FROM silver.crm_sales_details
WHERE sls_prd_key IS NULL 
   OR TRIM(sls_prd_key) = '';
GO


-- Check for NULL customer IDs
-- Expected result: no rows
SELECT *
FROM silver.crm_sales_details
WHERE sls_cust_id IS NULL;
GO


-- Check for invalid order dates
-- Expected result: no rows
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt IS NULL;
GO


-- Check for invalid shipping dates
-- Expected result: no rows
SELECT *
FROM silver.crm_sales_details
WHERE sls_ship_dt IS NULL;
GO


-- Check for invalid due dates
-- Expected result: no rows
SELECT *
FROM silver.crm_sales_details
WHERE sls_due_dt IS NULL;
GO


-- Check date logic
-- Order date should not be after shipping date or due date
-- Expected result: no rows
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;
GO


-- Check sales amount, quantity, and price
-- Expected result: no rows
SELECT *
FROM silver.crm_sales_details
WHERE sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0;
GO


-- Check sales calculation
-- Sales should equal quantity multiplied by price
-- Expected result: no rows
SELECT *
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price;
GO


-- Check sales customer IDs that do not exist in customer table
-- Expected result: no rows
SELECT DISTINCT 
    s.sls_cust_id
FROM silver.crm_sales_details s
LEFT JOIN silver.crm_cust_info c
    ON s.sls_cust_id = c.cst_id
WHERE c.cst_id IS NULL;
GO


-- Check sales product keys that do not exist in product table
-- Expected result: no rows
SELECT DISTINCT 
    s.sls_prd_key
FROM silver.crm_sales_details s
LEFT JOIN silver.crm_prd_info p
    ON s.sls_prd_key = p.prd_key
WHERE p.prd_key IS NULL;
GO



/* ============================================================
   CHECKS FOR silver.erp_cust_az12
   ============================================================ */

-- Check for NULL customer IDs
-- Expected result: no rows
SELECT *
FROM silver.erp_cust_az12
WHERE cid IS NULL 
   OR TRIM(cid) = '';
GO


-- Check for duplicate customer IDs
-- Expected result: no rows
SELECT 
    cid,
    COUNT(*) AS duplicate_count
FROM silver.erp_cust_az12
GROUP BY cid
HAVING COUNT(*) > 1;
GO


-- Check birth dates
-- Birth date should not be in the future
-- Expected result: no rows
SELECT *
FROM silver.erp_cust_az12
WHERE bdate > GETDATE();
GO


-- Check unrealistic birth dates
-- Expected result: review rows if any appear
SELECT *
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01';
GO


-- Check gender standardization
-- Expected values: Male, Female, n/a
SELECT DISTINCT gen
FROM silver.erp_cust_az12;
GO


-- Check invalid gender values
-- Expected result: no rows
SELECT *
FROM silver.erp_cust_az12
WHERE gen NOT IN ('Male', 'Female', 'n/a');
GO



/* ============================================================
   CHECKS FOR silver.erp_loc_a101
   ============================================================ */

-- Check for NULL customer IDs
-- Expected result: no rows
SELECT *
FROM silver.erp_loc_a101
WHERE cid IS NULL 
   OR TRIM(cid) = '';
GO


-- Check for duplicate customer IDs
-- Expected result: no rows
SELECT 
    cid,
    COUNT(*) AS duplicate_count
FROM silver.erp_loc_a101
GROUP BY cid
HAVING COUNT(*) > 1;
GO


-- Check country standardization
-- Review distinct country values
SELECT DISTINCT cntry
FROM silver.erp_loc_a101
ORDER BY cntry;
GO


-- Check for empty country values
-- Expected result: no rows if empty values were converted to n/a
SELECT *
FROM silver.erp_loc_a101
WHERE cntry IS NULL 
   OR TRIM(cntry) = '';
GO



/* ============================================================
   CHECKS FOR silver.erp_px_cat_g1v2
   ============================================================ */

-- Check for NULL category IDs
-- Expected result: no rows
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE id IS NULL 
   OR TRIM(id) = '';
GO


-- Check for duplicate category IDs
-- Expected result: no rows
SELECT 
    id,
    COUNT(*) AS duplicate_count
FROM silver.erp_px_cat_g1v2
GROUP BY id
HAVING COUNT(*) > 1;
GO


-- Check for unwanted spaces in category
-- Expected result: no rows
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat);
GO


-- Check for unwanted spaces in subcategory
-- Expected result: no rows
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE subcat != TRIM(subcat);
GO


-- Check for unwanted spaces in maintenance
-- Expected result: no rows
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE maintenance != TRIM(maintenance);
GO


-- Check for NULL category, subcategory, or maintenance
-- Expected result: no rows
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat IS NULL
   OR subcat IS NULL
   OR maintenance IS NULL;
GO


-- Review maintenance values
SELECT DISTINCT maintenance
FROM silver.erp_px_cat_g1v2;
GO
