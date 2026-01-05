-- Create simulation_events table for tracking significant simulation events
-- This allows the frontend to display important events like company creation, bankruptcies, etc.

CREATE TABLE IF NOT EXISTS simulation_events (
    id SERIAL PRIMARY KEY,
    city_name VARCHAR(255) NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('INFO', 'WARNING', 'CRITICAL')),
    description TEXT NOT NULL,
    event_data JSONB DEFAULT '{}',
    simulation_time INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_events_city_time ON simulation_events(city_name, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_events_severity ON simulation_events(severity, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_events_type ON simulation_events(event_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_events_sim_time ON simulation_events(city_name, simulation_time DESC);

-- Comments for documentation
COMMENT ON TABLE simulation_events IS 'Stores significant simulation events for display in the frontend';
COMMENT ON COLUMN simulation_events.event_type IS 'Type of event: COMPANY_CREATED, COMPANY_BANKRUPT, BANKING_CRISIS, etc.';
COMMENT ON COLUMN simulation_events.severity IS 'Severity level: INFO, WARNING, or CRITICAL';
COMMENT ON COLUMN simulation_events.event_data IS 'Additional structured data in JSON format';
COMMENT ON COLUMN simulation_events.simulation_time IS 'Simulation timestamp when event occurred';
