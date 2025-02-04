SELECT * FROM loan_payments;

-- 1. Create Staging Table and Copy Data

CREATE TABLE loan_payments_staging LIKE loan_payments;

INSERT INTO loan_payments_staging  
SELECT * FROM loan_payments;

SELECT * FROM loan_payments_staging;

-- 2. Check for Duplicates

SELECT loan_ID, COUNT(loan_ID) AS count_id  
FROM loan_payments_staging  
GROUP BY loan_ID  
HAVING count_id > 1;

-- Or

WITH duplicate_cte AS (  
    SELECT *,  
    ROW_NUMBER() OVER (PARTITION BY loan_ID, loan_status, Principal, terms, effective_date, due_date, paid_off_time, past_due_days, age, education, gender) AS row_num  
    FROM loan_payments_staging  
)  
SELECT * FROM duplicate_cte WHERE row_num > 1;

-- 3. Standardization: Loan Status and Principal Trimming

SELECT loan_status, COUNT(loan_status)  
FROM loan_payments_staging  
GROUP BY loan_status;

UPDATE loan_payments_staging  
SET Principal = TRIM(Principal);

-- 4. Rename terms column to terms_wk

ALTER TABLE loan_payments_staging  
CHANGE COLUMN terms terms_wk INT NULL DEFAULT NULL;

-- 5. Convert and Clean Date Columns

UPDATE loan_payments_staging  
SET effective_date = STR_TO_DATE(effective_date, '%m/%d/%Y');

ALTER TABLE loan_payments_staging  
MODIFY COLUMN effective_date DATE;

UPDATE loan_payments_staging  
SET due_date = STR_TO_DATE(due_date, '%m/%d/%Y');

ALTER TABLE loan_payments_staging  
MODIFY COLUMN due_date DATE;

-- 6. Clean and Convert Paid Off Time

UPDATE loan_payments_staging  
SET paid_off_time = NULL  
WHERE paid_off_time = '' OR paid_off_time IS NULL;

UPDATE loan_payments_staging  
SET paid_off_time = STR_TO_DATE(paid_off_time, '%m/%d/%Y %H:%i:%s');

ALTER TABLE loan_payments_staging  
MODIFY COLUMN paid_off_time DATETIME;

-- Convert to Date Only

UPDATE loan_payments_staging  
SET paid_off_time = DATE(paid_off_time);

ALTER TABLE loan_payments_staging  
MODIFY COLUMN paid_off_time DATE;

-- Rename to paid_off_date

ALTER TABLE loan_payments_staging  
CHANGE COLUMN paid_off_time paid_off_date DATE NULL DEFAULT NULL;

-- 7. Clean past_due_days Column

UPDATE loan_payments_staging  
SET past_due_days = NULL  
WHERE past_due_days = '';

ALTER TABLE loan_payments_staging  
MODIFY COLUMN past_due_days INT;

-- 8. Final Checks: Education and Gender 

SELECT DISTINCT education FROM loan_payments_staging;

SELECT DISTINCT gender FROM loan_payments_staging;
