-- =============================================================================
-- BACKWARD COMPATIBILITY VIEWS
-- Maps old SQLite table names to new PostgreSQL table names
-- Enables zero-code-change migration from existing applications
-- =============================================================================

-- =============================================================================
-- SIMULATION DATA COMPATIBILITY VIEWS
-- =============================================================================

-- TIME_DATA → economic_indicators
CREATE VIEW "TIME_DATA" AS 
SELECT 
    ROW_NUMBER() OVER (ORDER BY simulation_id, time_period) AS "ID",
    simulation_id,
    time_period AS "TIME",
    gdp_items AS "GDP_ITEMS", 
    demand AS "DEMAND",
    price AS "PRICE",
    unemployment AS "UNEMPLOYMENT",
    wages AS "WAGES", 
    interest_rate AS "INTEREST_RATE",
    investments AS "INVESTMENTS",
    gdp_nominal AS "GDP_NOMINAL",
    liquidity_reserve_ratio AS "LIQ_RES_RATIO",
    capital_reserve_ratio AS "CAP_RES_RATIO", 
    bank_dividend_ratio AS "BANK_DIV_RATIO"
FROM economic_indicators;

-- MONEY_DATA → financial_flows  
CREATE VIEW "MONEY_DATA" AS
SELECT
    ROW_NUMBER() OVER (ORDER BY simulation_id, time_period) AS "ID",
    simulation_id,
    time_period AS "TIME",
    bank_capital AS "BANK_CAPITAL",
    bank_loans AS "BANK_LOANS",
    bank_deposits AS "BANK_DEPOSITS", 
    bank_liquidity AS "BANK_LIQUIDITY",
    consumer_capital AS "CONSUMER_CAPITAL",
    consumer_deposits AS "CONSUMER_DEPOSITS",
    consumer_debts AS "CONSUMER_DEBTS",
    company_debts AS "COMPANY_DEBTS",
    company_capital AS "COMPANY_CAPITAL", 
    market_capital AS "MARKET_CAPITAL",
    city_capital AS "CITY_CAPITAL",
    total_capital AS "TOTAL_CAPITAL"
FROM financial_flows;

-- COMPANY_TABLE → companies
CREATE VIEW "COMPANY_TABLE" AS
SELECT
    ROW_NUMBER() OVER (ORDER BY simulation_id, time_period, name) AS "ID",
    simulation_id,
    time_period AS "TIME_STAMP", 
    name AS "NAME",
    capital AS "CAPITAL",
    stock AS "STOCK", 
    capacity AS "CAPACITY",
    debts AS "DEBTS",
    skill AS "PCSKILL",
    motivation AS "PCMOT",
    wage_constant AS "WAGE_CONST", 
    wage_change AS "WAGE_CH",
    investment AS "INVEST",
    profit_before_tax AS "PBR",
    decay_rate AS "DECAY",
    production_parameter AS "PROD_PARM",
    production_function AS "PROD_FCN",
    production AS "PRODUCTION", 
    employees AS "EMPLOYEES",
    item_efficiency AS "ITEM_EFFICIENCY",
    capacity_vs_efficiency_split AS "CAP_VS_EFF_SPLIT"
FROM companies;

-- CONSUMER_TABLE → consumers  
CREATE VIEW "CONSUMER_TABLE" AS
SELECT
    ROW_NUMBER() OVER (ORDER BY simulation_id, COALESCE(time_period, 0), name) AS "ID",
    simulation_id,
    name AS "NAME", 
    employer AS "EMPLOYER",
    items AS "ITEMS",
    capital AS "CAPITAL",
    deposits AS "DEPOSITS", 
    debts AS "DEBTS",
    skill AS "SKILL",
    motivation AS "MOT",
    spending_willingness AS "SPENDWILL",
    saving_willingness AS "SAVEWILL",
    borrowing_willingness AS "BORROWWILL",
    income AS "INCOME", 
    dividends AS "DIVIDENDS",
    transfers AS "TRANSFERS"
FROM consumers;

-- PARAMETERS → simulation_parameters
CREATE VIEW "PARAMETERS" AS  
SELECT
    ROW_NUMBER() OVER (ORDER BY simulation_id, parameter_name) AS "ID",
    simulation_id,
    parameter_name AS "PARAMETER",
    parameter_value AS "VALUE"
FROM simulation_parameters;

-- =============================================================================
-- COUNTRY-SPECIFIC VIEWS FOR LEGACY COMPATIBILITY
-- Creates per-country views that mimic the old separate database structure
-- =============================================================================

-- Function to create country-specific views dynamically
CREATE OR REPLACE FUNCTION create_country_views() 
RETURNS void AS $$
DECLARE
    country_rec RECORD;
    view_suffix TEXT;
BEGIN
    -- Loop through all countries and create views for each
    FOR country_rec IN SELECT name FROM countries WHERE is_active = TRUE LOOP
        view_suffix := REPLACE(country_rec.name, ' ', '_');
        
        -- Create country-specific TIME_DATA view
        EXECUTE FORMAT('
            CREATE OR REPLACE VIEW "TIME_DATA_%s" AS 
            SELECT * FROM "TIME_DATA" 
            WHERE simulation_id IN (
                SELECT s.id FROM simulations s 
                JOIN countries c ON s.country_id = c.id 
                WHERE c.name = %L
            )', view_suffix, country_rec.name);
            
        -- Create country-specific MONEY_DATA view  
        EXECUTE FORMAT('
            CREATE OR REPLACE VIEW "MONEY_DATA_%s" AS
            SELECT * FROM "MONEY_DATA"
            WHERE simulation_id IN (
                SELECT s.id FROM simulations s
                JOIN countries c ON s.country_id = c.id  
                WHERE c.name = %L
            )', view_suffix, country_rec.name);
            
        -- Create country-specific COMPANY_TABLE view
        EXECUTE FORMAT('
            CREATE OR REPLACE VIEW "COMPANY_TABLE_%s" AS
            SELECT * FROM "COMPANY_TABLE" 
            WHERE simulation_id IN (
                SELECT s.id FROM simulations s
                JOIN countries c ON s.country_id = c.id
                WHERE c.name = %L  
            )', view_suffix, country_rec.name);
            
        -- Create country-specific CONSUMER_TABLE view
        EXECUTE FORMAT('
            CREATE OR REPLACE VIEW "CONSUMER_TABLE_%s" AS
            SELECT * FROM "CONSUMER_TABLE"
            WHERE simulation_id IN (
                SELECT s.id FROM simulations s
                JOIN countries c ON s.country_id = c.id
                WHERE c.name = %L
            )', view_suffix, country_rec.name);
            
        -- Create country-specific PARAMETERS view
        EXECUTE FORMAT('
            CREATE OR REPLACE VIEW "PARAMETERS_%s" AS
            SELECT * FROM "PARAMETERS" 
            WHERE simulation_id IN (
                SELECT s.id FROM simulations s
                JOIN countries c ON s.country_id = c.id
                WHERE c.name = %L
            )', view_suffix, country_rec.name);
            
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Execute the function to create country-specific views
SELECT create_country_views();

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON VIEW "TIME_DATA" IS 'Backward compatibility view for legacy TIME_DATA table queries';
COMMENT ON VIEW "MONEY_DATA" IS 'Backward compatibility view for legacy MONEY_DATA table queries';  
COMMENT ON VIEW "COMPANY_TABLE" IS 'Backward compatibility view for legacy COMPANY_TABLE queries';
COMMENT ON VIEW "CONSUMER_TABLE" IS 'Backward compatibility view for legacy CONSUMER_TABLE queries';
COMMENT ON VIEW "PARAMETERS" IS 'Backward compatibility view for legacy PARAMETERS table queries';
COMMENT ON FUNCTION create_country_views() IS 'Creates country-specific views for legacy database-per-country compatibility';