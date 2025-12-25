-- COMPANY_DATA table for tracking company metrics across simulation cycles
-- This table stores comprehensive company data including capital, production, employees, and efficiency metrics

CREATE TABLE IF NOT EXISTS company_data (
    id SERIAL PRIMARY KEY,
    city_name VARCHAR(255) NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    time_stamp INTEGER NOT NULL,
    capital INTEGER NOT NULL,
    stock INTEGER NOT NULL,
    capacity INTEGER NOT NULL,
    debts INTEGER NOT NULL,
    pcskill DECIMAL NOT NULL,
    pcmot DECIMAL NOT NULL,
    wage_const DECIMAL NOT NULL,
    wage_ch DECIMAL NOT NULL,
    invest INTEGER NOT NULL,
    pbr DECIMAL NOT NULL,
    decay DECIMAL NOT NULL,
    prod_parm DECIMAL NOT NULL,
    prod_fcn INTEGER NOT NULL,
    production INTEGER NOT NULL,
    employees INTEGER NOT NULL,
    item_efficiency DECIMAL NOT NULL,
    cap_vs_eff_split DECIMAL NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure one record per city per company per time period
    UNIQUE(city_name, company_name, time_stamp)
);

-- Index for efficient queries by city, company and time range
CREATE INDEX IF NOT EXISTS idx_company_data_city_company_time ON company_data(city_name, company_name, time_stamp);

-- Index for time-based queries across all companies
CREATE INDEX IF NOT EXISTS idx_company_data_time ON company_data(time_stamp);

-- Index for company lookups
CREATE INDEX IF NOT EXISTS idx_company_data_company ON company_data(company_name);

-- Comments for documentation
COMMENT ON TABLE company_data IS 'Company performance data across simulation cycles';
COMMENT ON COLUMN company_data.city_name IS 'Name of the city/country';
COMMENT ON COLUMN company_data.company_name IS 'Name of the company';
COMMENT ON COLUMN company_data.time_stamp IS 'Simulation cycle/timestamp';
COMMENT ON COLUMN company_data.capital IS 'Company capital';
COMMENT ON COLUMN company_data.stock IS 'Inventory/stock level';
COMMENT ON COLUMN company_data.capacity IS 'Production capacity';
COMMENT ON COLUMN company_data.debts IS 'Company debts';
COMMENT ON COLUMN company_data.pcskill IS 'Average employee skill level';
COMMENT ON COLUMN company_data.pcmot IS 'Employee motivation level';
COMMENT ON COLUMN company_data.wage_const IS 'Base wage constant';
COMMENT ON COLUMN company_data.wage_ch IS 'Wage change rate';
COMMENT ON COLUMN company_data.invest IS 'Investment amount';
COMMENT ON COLUMN company_data.pbr IS 'Price-to-book ratio';
COMMENT ON COLUMN company_data.decay IS 'Capital decay rate';
COMMENT ON COLUMN company_data.prod_parm IS 'Production parameter';
COMMENT ON COLUMN company_data.prod_fcn IS 'Production function type';
COMMENT ON COLUMN company_data.production IS 'Production output';
COMMENT ON COLUMN company_data.employees IS 'Number of employees';
COMMENT ON COLUMN company_data.item_efficiency IS 'Item efficiency metric';
COMMENT ON COLUMN company_data.cap_vs_eff_split IS 'Capital vs efficiency split ratio';
