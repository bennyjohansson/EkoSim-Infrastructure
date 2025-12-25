-- MONEY_DATA table for tracking monetary flows across simulation cycles
-- This table stores comprehensive financial data for banks, consumers, companies, and the city

CREATE TABLE IF NOT EXISTS money_data (
    id SERIAL PRIMARY KEY,
    city_name VARCHAR(255) NOT NULL,
    time INTEGER NOT NULL,
    bank_capital INTEGER NOT NULL,
    bank_loans INTEGER NOT NULL,
    bank_deposits INTEGER NOT NULL,
    bank_liquidity INTEGER NOT NULL,
    consumer_capital INTEGER NOT NULL,
    consumer_deposits INTEGER NOT NULL,
    consumer_debts INTEGER NOT NULL,
    company_debts INTEGER NOT NULL,
    company_capital INTEGER NOT NULL,
    market_capital INTEGER NOT NULL,
    city_capital INTEGER NOT NULL,
    total_capital INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure one record per city per time period
    UNIQUE(city_name, time)
);

-- Index for efficient queries by city and time range
CREATE INDEX IF NOT EXISTS idx_money_data_city_time ON money_data(city_name, time);

-- Index for time-based queries across cities
CREATE INDEX IF NOT EXISTS idx_money_data_time ON money_data(time);

-- Index for latest data queries
CREATE INDEX IF NOT EXISTS idx_money_data_created ON money_data(created_at);

-- Comments for documentation
COMMENT ON TABLE money_data IS 'Monetary flow data across simulation cycles';
COMMENT ON COLUMN money_data.city_name IS 'Name of the city/country';
COMMENT ON COLUMN money_data.time IS 'Simulation cycle/timestamp';
COMMENT ON COLUMN money_data.bank_capital IS 'Total bank capital';
COMMENT ON COLUMN money_data.bank_loans IS 'Total loans issued by banks';
COMMENT ON COLUMN money_data.bank_deposits IS 'Total deposits in banks';
COMMENT ON COLUMN money_data.bank_liquidity IS 'Bank liquidity reserves';
COMMENT ON COLUMN money_data.consumer_capital IS 'Total consumer capital';
COMMENT ON COLUMN money_data.consumer_deposits IS 'Consumer deposits in banks';
COMMENT ON COLUMN money_data.consumer_debts IS 'Total consumer debts';
COMMENT ON COLUMN money_data.company_debts IS 'Total company debts';
COMMENT ON COLUMN money_data.company_capital IS 'Total company capital';
COMMENT ON COLUMN money_data.market_capital IS 'Market capital';
COMMENT ON COLUMN money_data.city_capital IS 'City/government capital';
COMMENT ON COLUMN money_data.total_capital IS 'Total capital in the economy';
