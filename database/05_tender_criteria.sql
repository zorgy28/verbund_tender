-- ===============================================
-- TENDER CRITERIA TABLES - STANDARDIZED PROPOSAL
-- For project: https://fljvxaqqxlioxljkchte.supabase.co
-- German localized system
-- ===============================================

-- ===============================================
-- MAIN TENDER CRITERIA TABLE
-- ===============================================

CREATE TABLE tender_criteria (
    -- Primary Key & Timestamps
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Foreign Key Relations
    tender_id BIGINT NOT NULL REFERENCES tenders(id) ON DELETE CASCADE,
    
    -- Basic Information (from your diagram)
    title TEXT NOT NULL,
    description TEXT,
    category TEXT, -- Free text for flexible categorization
    
    -- Classification  
    explicitness TEXT NOT NULL DEFAULT 'explicit', -- 'explicit' or 'implicit'
    reasoning_for_implicit TEXT, -- Reasoning when criteria is implicitly derived
    
    -- Validation & Verification  
    validation_condition JSONB, -- Your field - JSON validation rules
    verification_method TEXT, -- Your field - how to verify this criteria
    
    -- Scoring & Assessment
    weight DECIMAL(5,2) DEFAULT 1.00, -- Criteria weight (0.00-100.00)
    is_binary_validation BOOLEAN DEFAULT false, -- Whether this is yes/no or scored evaluation
    
    -- Flexible metadata for future extensions
    metadata JSONB DEFAULT '{}'
);

-- ===============================================
-- TENDER CRITERIA DEPENDENCIES TABLE
-- ===============================================

CREATE TABLE tender_criteria_dependencies (
    -- Primary Key & Timestamps
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Foreign Key Relations
    criteria_id BIGINT NOT NULL REFERENCES tender_criteria(id) ON DELETE CASCADE,
    dependency_id BIGINT NOT NULL REFERENCES tender_criteria(id) ON DELETE CASCADE,
    
    -- Dependency Properties
    dependency_type TEXT DEFAULT 'requires', -- requires, conflicts, enhances
    dependency_description TEXT,
    is_active BOOLEAN DEFAULT true,
    
    -- Ensure no self-references
    CONSTRAINT chk_no_self_dependency CHECK (criteria_id != dependency_id),
    
    -- Unique constraint to prevent duplicates
    UNIQUE(criteria_id, dependency_id)
);

-- ===============================================
-- TENDER CRITERIA SOURCE TABLE (Evidence Tracking)
-- ===============================================

CREATE TABLE tender_criteria_source (
    -- Primary Key & Timestamps
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Foreign Key Relations
    tender_id BIGINT NOT NULL REFERENCES tenders(id) ON DELETE CASCADE,
    criteria_id BIGINT NOT NULL REFERENCES tender_criteria(id) ON DELETE CASCADE,
    tender_document_id BIGINT REFERENCES tender_documents(id) ON DELETE SET NULL,
    tender_image_id BIGINT REFERENCES tender_images(id) ON DELETE SET NULL,
    
    -- Evidence Details
    evidence_extract TEXT, -- Your field - extracted evidence text
    
    -- Location Information
    page_number INTEGER,
    section_reference TEXT,
    
    -- Ensure at least one document or image reference
    CONSTRAINT chk_has_source CHECK (
        tender_document_id IS NOT NULL OR tender_image_id IS NOT NULL
    )
);

-- ===============================================
-- INDEXES FOR PERFORMANCE
-- ===============================================

-- Main table indexes
CREATE INDEX idx_tender_criteria_tender_id ON tender_criteria(tender_id);
CREATE INDEX idx_tender_criteria_category ON tender_criteria(category);
CREATE INDEX idx_tender_criteria_explicitness ON tender_criteria(explicitness);
CREATE INDEX idx_tender_criteria_weight ON tender_criteria(weight) WHERE weight > 0;

-- Dependencies indexes
CREATE INDEX idx_criteria_dependencies_criteria_id ON tender_criteria_dependencies(criteria_id);
CREATE INDEX idx_criteria_dependencies_dependency_id ON tender_criteria_dependencies(dependency_id);

-- Source tracking indexes
CREATE INDEX idx_criteria_source_criteria_id ON tender_criteria_source(criteria_id);
CREATE INDEX idx_criteria_source_tender_id ON tender_criteria_source(tender_id);
CREATE INDEX idx_criteria_source_document_id ON tender_criteria_source(tender_document_id);
CREATE INDEX idx_criteria_source_image_id ON tender_criteria_source(tender_image_id);

-- Composite indexes for common queries
CREATE INDEX idx_criteria_tender_category ON tender_criteria(tender_id, category);
CREATE INDEX idx_criteria_tender_weight ON tender_criteria(tender_id, weight);

-- ===============================================
-- TRIGGERS
-- ===============================================

-- Auto-update timestamp for main table
CREATE TRIGGER update_tender_criteria_updated_at 
    BEFORE UPDATE ON tender_criteria
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===============================================
-- UTILITY FUNCTIONS
-- ===============================================

-- Function to get criteria by category
CREATE OR REPLACE FUNCTION get_criteria_by_category(
    p_tender_id BIGINT,
    p_category TEXT
)
RETURNS TABLE (
    id BIGINT,
    title TEXT,
    description TEXT,
    weight DECIMAL,
    explicitness TEXT,
    verification_method TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tc.id,
        tc.title,
        tc.description,
        tc.weight,
        tc.explicitness,
        tc.verification_method
    FROM tender_criteria tc
    WHERE 
        tc.tender_id = p_tender_id
        AND tc.category = p_category
    ORDER BY tc.weight DESC, tc.title ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check criteria dependencies
CREATE OR REPLACE FUNCTION check_criteria_dependencies(
    p_criteria_id BIGINT
)
RETURNS TABLE (
    dependency_id BIGINT,
    dependency_title TEXT,
    dependency_type TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tcd.dependency_id,
        tc.title as dependency_title,
        tcd.dependency_type
    FROM tender_criteria_dependencies tcd
    JOIN tender_criteria tc ON tc.id = tcd.dependency_id
    WHERE 
        tcd.criteria_id = p_criteria_id
        AND tcd.is_active = true
    ORDER BY tcd.dependency_type, tc.title;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get evidence sources for criteria
CREATE OR REPLACE FUNCTION get_criteria_evidence(
    p_criteria_id BIGINT
)
RETURNS TABLE (
    source_id BIGINT,
    evidence_extract TEXT,
    document_name TEXT,
    page_number INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tcs.id as source_id,
        tcs.evidence_extract,
        td.file_name as document_name,
        tcs.page_number
    FROM tender_criteria_source tcs
    LEFT JOIN tender_documents td ON td.id = tcs.tender_document_id
    WHERE tcs.criteria_id = p_criteria_id
    ORDER BY tcs.created_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===============================================
-- ROW LEVEL SECURITY
-- ===============================================

ALTER TABLE tender_criteria ENABLE ROW LEVEL SECURITY;
ALTER TABLE tender_criteria_dependencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE tender_criteria_source ENABLE ROW LEVEL SECURITY;

-- Basic policies for service role
CREATE POLICY "Allow all for service role" ON tender_criteria FOR ALL TO service_role USING (true);
CREATE POLICY "Allow all for service role" ON tender_criteria_dependencies FOR ALL TO service_role USING (true);
CREATE POLICY "Allow all for service role" ON tender_criteria_source FOR ALL TO service_role USING (true);

-- Read-only policies for authenticated users (adjust based on your auth needs)
CREATE POLICY "Allow read for authenticated users" ON tender_criteria FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow read for authenticated users" ON tender_criteria_dependencies FOR SELECT TO authenticated USING (is_active = true);
CREATE POLICY "Allow read for authenticated users" ON tender_criteria_source FOR SELECT TO authenticated USING (true);

-- ===============================================
-- COMMENTS FOR DOCUMENTATION
-- ===============================================

COMMENT ON TABLE tender_criteria IS 'Evaluation criteria and requirements extracted from tender documents';
COMMENT ON COLUMN tender_criteria.title IS 'Title or name of the criteria';
COMMENT ON COLUMN tender_criteria.explicitness IS 'Whether criteria is explicitly stated or implicitly derived';
COMMENT ON COLUMN tender_criteria.reasoning_for_implicit IS 'Reasoning when criteria is implicitly derived';
COMMENT ON COLUMN tender_criteria.validation_condition IS 'JSON rules for validating this criteria';
COMMENT ON COLUMN tender_criteria.weight IS 'Relative weight/importance of this criteria (0.00-100.00)';
COMMENT ON COLUMN tender_criteria.is_binary_validation IS 'Whether this is a yes/no validation or scored evaluation';

COMMENT ON TABLE tender_criteria_dependencies IS 'Relationships and dependencies between criteria';
COMMENT ON TABLE tender_criteria_source IS 'Evidence sources linking criteria to documents and images';