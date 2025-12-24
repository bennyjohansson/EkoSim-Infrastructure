-- =============================================================================
-- WORLD TABLE
-- Global list of all cities/economies in the simulation
-- =============================================================================

CREATE TABLE IF NOT EXISTS world_table (
    id SERIAL PRIMARY KEY,
    city_name VARCHAR(255) NOT NULL UNIQUE,
    no_consumers INTEGER NOT NULL,
    email VARCHAR(255) NOT NULL,
    created INTEGER NOT NULL
);

-- Create backward compatibility view with uppercase column names for legacy code
CREATE OR REPLACE VIEW "WORLD_TABLE" AS 
SELECT 
    id AS "ID",
    city_name AS "CITY_NAME",
    no_consumers AS "NO_CONSUMERS",
    email AS "EMAIL",
    created AS "CREATED"
FROM world_table;

-- Add some indexes for performance
CREATE INDEX IF NOT EXISTS idx_world_table_city_name ON world_table(city_name);
CREATE INDEX IF NOT EXISTS idx_world_table_email ON world_table(email);

-- Comment for documentation
COMMENT ON TABLE world_table IS 'Global list of all cities/economies in the simulation';
COMMENT ON VIEW "WORLD_TABLE" IS 'Backward compatibility view for legacy WORLD_TABLE queries';
