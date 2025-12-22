-- =============================================================================
-- HIGH SCORES TABLE
-- Tracks best simulation performance across different metrics
-- =============================================================================

-- High Scores table
CREATE TABLE high_scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    country VARCHAR(100) NOT NULL,
    growth_rate DECIMAL NOT NULL,
    palma_ratio DECIMAL NOT NULL,
    environmental_impact DECIMAL NOT NULL,
    achieved_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Optional user tracking
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    simulation_id UUID REFERENCES simulations(id) ON DELETE SET NULL,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_high_scores_country ON high_scores(country);
CREATE INDEX idx_high_scores_growth ON high_scores(growth_rate DESC);
CREATE INDEX idx_high_scores_palma ON high_scores(palma_ratio ASC);  -- Lower is better for inequality
CREATE INDEX idx_high_scores_environment ON high_scores(environmental_impact ASC);  -- Lower is better
CREATE INDEX idx_high_scores_achieved ON high_scores(achieved_at DESC);
CREATE INDEX idx_high_scores_user ON high_scores(user_id);

COMMENT ON TABLE high_scores IS 'High scores tracking economic performance metrics across simulations';
COMMENT ON COLUMN high_scores.growth_rate IS 'Economic growth rate achieved';
COMMENT ON COLUMN high_scores.palma_ratio IS 'Income inequality measure (lower is better)';
COMMENT ON COLUMN high_scores.environmental_impact IS 'Environmental impact score (lower is better)';
COMMENT ON COLUMN high_scores.achieved_at IS 'When this score was achieved';