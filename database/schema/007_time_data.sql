-- =============================================================================
-- TIME_DATA TABLE - Economic Time Series Data
-- Tracks GDP, unemployment, wages, interest rates, and other key indicators
-- per city per simulation cycle
-- =============================================================================

CREATE TABLE IF NOT EXISTS time_data (
    id SERIAL PRIMARY KEY,
    city_name VARCHAR(255) NOT NULL,
    time INTEGER NOT NULL,
    gdp_items DOUBLE PRECISION,
    demand DOUBLE PRECISION,
    price DOUBLE PRECISION,
    unemployment DOUBLE PRECISION,
    wages DOUBLE PRECISION,
    interest_rate DOUBLE PRECISION,
    investments DOUBLE PRECISION,
    gdp_nominal DOUBLE PRECISION,
    liquidity_reserve_ratio DOUBLE PRECISION,
    capital_reserve_ratio DOUBLE PRECISION,
    bank_dividend_ratio DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Prevent duplicate entries for same city/time
    CONSTRAINT unique_city_time UNIQUE (city_name, time)
);

-- Index for efficient time-series queries
CREATE INDEX IF NOT EXISTS idx_time_data_city_time ON time_data(city_name, time DESC);
CREATE INDEX IF NOT EXISTS idx_time_data_city ON time_data(city_name);
CREATE INDEX IF NOT EXISTS idx_time_data_time ON time_data(time);

-- Comments for documentation
COMMENT ON TABLE time_data IS 'Economic indicators time series data per city per simulation cycle';
COMMENT ON COLUMN time_data.city_name IS 'Name of the city/economy';
COMMENT ON COLUMN time_data.time IS 'Simulation cycle/timestamp';
COMMENT ON COLUMN time_data.gdp_items IS 'GDP measured in items produced';
COMMENT ON COLUMN time_data.demand IS 'Consumer demand';
COMMENT ON COLUMN time_data.price IS 'Average price level';
COMMENT ON COLUMN time_data.unemployment IS 'Unemployment rate';
COMMENT ON COLUMN time_data.wages IS 'Average wage level';
COMMENT ON COLUMN time_data.interest_rate IS 'Current interest rate';
COMMENT ON COLUMN time_data.investments IS 'Investment level';
COMMENT ON COLUMN time_data.gdp_nominal IS 'Nominal GDP';
COMMENT ON COLUMN time_data.liquidity_reserve_ratio IS 'Bank liquidity reserve ratio';
COMMENT ON COLUMN time_data.capital_reserve_ratio IS 'Bank capital reserve ratio';
COMMENT ON COLUMN time_data.bank_dividend_ratio IS 'Bank dividend payout ratio';
