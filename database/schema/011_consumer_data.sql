-- Consumer data table for current consumer state
-- Stores snapshot of consumer state (no time-series history)

CREATE TABLE IF NOT EXISTS consumer_data (
    id SERIAL PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    consumer_name VARCHAR(100) NOT NULL,
    employer VARCHAR(100),
    items INTEGER NOT NULL,
    capital DOUBLE PRECISION NOT NULL,
    deposits DOUBLE PRECISION NOT NULL,
    debts DOUBLE PRECISION NOT NULL,
    skill DOUBLE PRECISION NOT NULL,
    mot DOUBLE PRECISION NOT NULL,
    spendwill DOUBLE PRECISION NOT NULL,
    savewill DOUBLE PRECISION NOT NULL,
    borrowwill DOUBLE PRECISION NOT NULL,
    income DOUBLE PRECISION NOT NULL,
    dividends DOUBLE PRECISION NOT NULL,
    transfers DOUBLE PRECISION NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(city_name, consumer_name)
);

-- Index for fast lookups by city
CREATE INDEX IF NOT EXISTS idx_consumer_data_city ON consumer_data(city_name);

-- Comments
COMMENT ON TABLE consumer_data IS 'Current consumer state snapshot for simulation';
COMMENT ON COLUMN consumer_data.city_name IS 'Name of the city';
COMMENT ON COLUMN consumer_data.consumer_name IS 'Name of the consumer';
COMMENT ON COLUMN consumer_data.employer IS 'Current employer company name';
