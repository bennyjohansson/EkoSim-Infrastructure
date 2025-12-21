-- =============================================================================
-- INITIAL SEED DATA FOR EKOSIM DATABASE
-- =============================================================================

-- Insert existing countries based on current SQLite databases
INSERT INTO countries (name, display_name, description, is_active) VALUES
    ('Bennyland', 'Benny Land', 'Primary development and testing country', TRUE),
    ('Saraland', 'Sara Land', 'Secondary testing environment', TRUE),
    ('Bennyworld', 'Benny World', 'Extended simulation environment', TRUE),
    ('Wernerland', 'Werner Land', 'Historical simulation data', TRUE),
    ('TestCity', 'Test City', 'Testing and validation environment', TRUE),
    ('ComparisonCity', 'Comparison City', 'Comparative analysis environment', TRUE);

-- Create initial simulations for each country (these will be populated by migration scripts)
INSERT INTO simulations (country_id, name, status) 
SELECT 
    id, 
    'Initial Simulation - ' || display_name,
    'running'
FROM countries 
WHERE is_active = TRUE;

-- Insert common simulation parameters (these are typical values found in SQLite databases)
INSERT INTO simulation_parameters (simulation_id, parameter_name, parameter_value)
SELECT 
    s.id,
    param.name,
    param.value
FROM simulations s
CROSS JOIN (
    VALUES 
        ('TARGET_INFLATION', 0.02),
        ('BASE_INTEREST_RATE', 0.04),
        ('CAPITAL_RESERVE_RATIO', 0.4),
        ('LIQUIDITY_RESERVE_RATIO', 0.5),
        ('BANK_DIVIDEND_RATIO', 0.1),
        ('MAX_UNEMPLOYMENT', 0.15),
        ('MIN_WAGE_FACTOR', 1.0),
        ('INVESTMENT_THRESHOLD', 1000000),
        ('CONSUMER_CONFIDENCE', 0.8),
        ('COMPANY_CONFIDENCE', 0.75)
) AS param(name, value);

-- Create a demo admin user (password should be changed in production)
INSERT INTO users (username, email, password_hash, level, role, assigned_country, tenant_id) VALUES
    ('admin', 'admin@ekosim.local', '$2b$12$demo_hash_change_in_production', 'expert', 'admin', 'Bennyland', 'default');

-- Create demo users for testing (these match existing patterns)
INSERT INTO users (username, email, password_hash, level, role, assigned_country, tenant_id) VALUES
    ('demo_user', 'demo@ekosim.local', '$2b$12$demo_hash_change_in_production', 'beginner', 'user', 'TestCity', 'default'),
    ('test_user', 'test@ekosim.local', '$2b$12$demo_hash_change_in_production', 'intermediate', 'user', 'Saraland', 'default');

COMMENT ON TABLE countries IS 'Countries available for economic simulation';
COMMENT ON TABLE simulations IS 'Individual simulation runs within countries';
COMMENT ON TABLE users IS 'User accounts with multi-tenant support';
COMMENT ON TABLE simulation_parameters IS 'Configuration parameters for simulations';
COMMENT ON TABLE economic_indicators IS 'Time-series economic data from simulations';
COMMENT ON TABLE financial_flows IS 'Time-series financial flow data';
COMMENT ON TABLE companies IS 'Company data tracked over simulation time';
COMMENT ON TABLE consumers IS 'Consumer/citizen data tracked over simulation time';