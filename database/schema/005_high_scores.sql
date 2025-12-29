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

-- =============================================================================
-- LEGACY COMPATIBILITY VIEW FOR C++ BACKEND
-- Maps old HIGH_SCORE table structure to new high_scores table
-- PostgreSQL converts unquoted identifiers to lowercase, so we use lowercase
-- =============================================================================

-- Create an updatable view that allows INSERTs from legacy C++ code
CREATE VIEW high_score AS
SELECT
    country,
    growth_rate AS growth,
    palma_ratio AS palma,
    environmental_impact AS env_imp,
    achieved_at AS timenow
FROM high_scores;

-- Create INSTEAD OF INSERT trigger to handle inserts through the view
CREATE OR REPLACE FUNCTION insert_high_score()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO high_scores (country, growth_rate, palma_ratio, environmental_impact, achieved_at)
    VALUES (NEW.country, NEW.growth, NEW.palma, NEW.env_imp, NEW.timenow);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER high_score_insert
INSTEAD OF INSERT ON high_score
FOR EACH ROW
EXECUTE FUNCTION insert_high_score();