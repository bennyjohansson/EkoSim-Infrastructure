-- Parameters table for simulation configuration
-- Stores key-value configuration parameters for each city

CREATE TABLE IF NOT EXISTS parameters (
    id SERIAL PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    parameter VARCHAR(100) NOT NULL,
    value DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(city_name, parameter)
);

-- Index for fast parameter lookups by city
CREATE INDEX IF NOT EXISTS idx_parameters_city ON parameters(city_name);

-- Index for fast lookups by city and parameter
CREATE INDEX IF NOT EXISTS idx_parameters_city_param ON parameters(city_name, parameter);

-- Comment on table
COMMENT ON TABLE parameters IS 'Simulation configuration parameters for each city';
COMMENT ON COLUMN parameters.city_name IS 'Name of the city';
COMMENT ON COLUMN parameters.parameter IS 'Parameter name (e.g., InterestRateMethod, TargetInterestRate)';
COMMENT ON COLUMN parameters.value IS 'Parameter value';
