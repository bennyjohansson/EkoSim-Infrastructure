-- =============================================================================
-- EKOSIM UNIFIED DATABASE SCHEMA
-- Consolidates user management and simulation data into single PostgreSQL database
-- =============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Custom Types
CREATE TYPE user_level AS ENUM ('beginner', 'intermediate', 'expert');
CREATE TYPE user_role AS ENUM ('user', 'admin', 'test');
CREATE TYPE simulation_status AS ENUM ('running', 'paused', 'stopped', 'completed');

-- =============================================================================
-- USER MANAGEMENT & AUTHENTICATION
-- =============================================================================

-- Users table (migrated from EkoWeb/myDB/users.db)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    level user_level DEFAULT 'beginner',
    role user_role DEFAULT 'user',
    assigned_country VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    tenant_id VARCHAR(100) DEFAULT 'default',
    metadata JSONB DEFAULT '{}',
    CONSTRAINT unique_email_per_tenant UNIQUE(email, tenant_id)
);

-- User sessions table
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- COUNTRIES & SIMULATIONS
-- =============================================================================

-- Countries table (replaces multiple SQLite databases)
CREATE TABLE countries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(255),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- Simulations table (tracks simulation runs per country)
CREATE TABLE simulations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    country_id UUID REFERENCES countries(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    status simulation_status DEFAULT 'running',
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- =============================================================================
-- SIMULATION CONFIGURATION & PARAMETERS
-- =============================================================================

-- Simulation parameters (migrated from PARAMETERS table in each country DB)
CREATE TABLE simulation_parameters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    simulation_id UUID REFERENCES simulations(id) ON DELETE CASCADE,
    parameter_name VARCHAR(100) NOT NULL,
    parameter_value DECIMAL NOT NULL,
    set_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_param_per_simulation UNIQUE(simulation_id, parameter_name)
);

-- =============================================================================
-- TIME SERIES DATA
-- =============================================================================

-- Economic indicators (migrated from TIME_DATA table)
CREATE TABLE economic_indicators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    simulation_id UUID REFERENCES simulations(id) ON DELETE CASCADE,
    time_period INTEGER NOT NULL,
    gdp_items INTEGER NOT NULL,
    demand INTEGER NOT NULL,
    price DECIMAL NOT NULL,
    unemployment DECIMAL NOT NULL,
    wages DECIMAL NOT NULL,
    interest_rate DECIMAL NOT NULL,
    investments DECIMAL NOT NULL,
    gdp_nominal INTEGER NOT NULL,
    liquidity_reserve_ratio DECIMAL NOT NULL,
    capital_reserve_ratio DECIMAL NOT NULL,
    bank_dividend_ratio DECIMAL NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_indicator_per_time UNIQUE(simulation_id, time_period)
);

-- Financial flows (migrated from MONEY_DATA table)
CREATE TABLE financial_flows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    simulation_id UUID REFERENCES simulations(id) ON DELETE CASCADE,
    time_period INTEGER NOT NULL,
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
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_flow_per_time UNIQUE(simulation_id, time_period)
);

-- =============================================================================
-- ENTITY DATA
-- =============================================================================

-- Companies data (migrated from COMPANY_TABLE)
CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    simulation_id UUID REFERENCES simulations(id) ON DELETE CASCADE,
    time_period INTEGER NOT NULL,
    name VARCHAR(255) NOT NULL,
    capital DECIMAL NOT NULL,
    stock INTEGER NOT NULL,
    capacity INTEGER NOT NULL,
    debts INTEGER NOT NULL,
    skill DECIMAL NOT NULL,
    motivation DECIMAL NOT NULL,
    wage_constant DECIMAL NOT NULL,
    wage_change DECIMAL NOT NULL,
    investment DECIMAL NOT NULL,
    profit_before_tax DECIMAL NOT NULL,
    decay_rate DECIMAL NOT NULL,
    production_parameter DECIMAL NOT NULL,
    production_function INTEGER NOT NULL,
    production INTEGER NOT NULL,
    employees INTEGER NOT NULL,
    item_efficiency DECIMAL NOT NULL,
    capacity_vs_efficiency_split DECIMAL NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Consumers data (migrated from CONSUMER_TABLE)
CREATE TABLE consumers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    simulation_id UUID REFERENCES simulations(id) ON DELETE CASCADE,
    time_period INTEGER DEFAULT NULL, -- NULL for static data, timestamp for historical
    name VARCHAR(255) NOT NULL,
    employer VARCHAR(255),
    items INTEGER NOT NULL,
    capital DECIMAL NOT NULL,
    deposits DECIMAL NOT NULL,
    debts DECIMAL NOT NULL,
    skill DECIMAL NOT NULL,
    motivation DECIMAL NOT NULL,
    spending_willingness DECIMAL NOT NULL,
    saving_willingness DECIMAL NOT NULL,
    borrowing_willingness DECIMAL NOT NULL,
    income DECIMAL NOT NULL,
    dividends DECIMAL NOT NULL,
    transfers DECIMAL NOT NULL,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);