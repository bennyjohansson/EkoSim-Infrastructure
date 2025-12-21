-- =============================================================================
-- PERFORMANCE INDEXES FOR EKOSIM DATABASE
-- =============================================================================

-- =============================================================================
-- USER MANAGEMENT INDEXES
-- =============================================================================

-- User lookup performance
CREATE INDEX idx_users_email_tenant ON users(email, tenant_id);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_assigned_country ON users(assigned_country);
CREATE INDEX idx_users_active ON users(is_active) WHERE is_active = TRUE;

-- Session management
CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_expires ON user_sessions(expires_at);
CREATE INDEX idx_user_sessions_token ON user_sessions(token_hash);

-- =============================================================================
-- SIMULATION INDEXES
-- =============================================================================

-- Country and simulation lookups
CREATE INDEX idx_countries_name ON countries(name);
CREATE INDEX idx_countries_active ON countries(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_simulations_country ON simulations(country_id);
CREATE INDEX idx_simulations_status ON simulations(status);
CREATE INDEX idx_simulations_created_by ON simulations(created_by);

-- Parameter lookups
CREATE INDEX idx_sim_params_simulation ON simulation_parameters(simulation_id);
CREATE INDEX idx_sim_params_name ON simulation_parameters(parameter_name);

-- =============================================================================
-- TIME SERIES INDEXES (Critical for chart performance)
-- =============================================================================

-- Economic indicators - optimized for time-based queries
CREATE INDEX idx_economic_indicators_sim_time ON economic_indicators(simulation_id, time_period);
CREATE INDEX idx_economic_indicators_sim_recorded ON economic_indicators(simulation_id, recorded_at);
CREATE INDEX idx_economic_indicators_time ON economic_indicators(time_period);

-- Financial flows - optimized for dashboard queries  
CREATE INDEX idx_financial_flows_sim_time ON financial_flows(simulation_id, time_period);
CREATE INDEX idx_financial_flows_sim_recorded ON financial_flows(simulation_id, recorded_at);
CREATE INDEX idx_financial_flows_time ON financial_flows(time_period);

-- =============================================================================
-- ENTITY INDEXES
-- =============================================================================

-- Company data - optimized for company tracking over time
CREATE INDEX idx_companies_sim_time ON companies(simulation_id, time_period);
CREATE INDEX idx_companies_sim_name_time ON companies(simulation_id, name, time_period);
CREATE INDEX idx_companies_name ON companies(name);
CREATE INDEX idx_companies_recorded ON companies(recorded_at);

-- Consumer data - optimized for population analysis
CREATE INDEX idx_consumers_sim_time ON consumers(simulation_id, time_period);
CREATE INDEX idx_consumers_sim_name ON consumers(simulation_id, name);
CREATE INDEX idx_consumers_employer ON consumers(employer);
CREATE INDEX idx_consumers_recorded ON consumers(recorded_at);

-- =============================================================================
-- COMPOSITE INDEXES FOR COMMON QUERY PATTERNS
-- =============================================================================

-- Dashboard queries: latest data per simulation
CREATE INDEX idx_latest_economic_data ON economic_indicators(simulation_id, time_period DESC);
CREATE INDEX idx_latest_financial_data ON financial_flows(simulation_id, time_period DESC);
CREATE INDEX idx_latest_company_data ON companies(simulation_id, time_period DESC);

-- Chart queries: time series for specific simulations
CREATE INDEX idx_timeseries_economics ON economic_indicators(simulation_id, time_period, price, unemployment, interest_rate);
CREATE INDEX idx_timeseries_money ON financial_flows(simulation_id, time_period, total_capital, bank_capital);

-- User activity tracking
CREATE INDEX idx_user_country_activity ON simulations(created_by, country_id, started_at);