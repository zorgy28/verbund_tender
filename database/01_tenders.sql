-- ===============================================
-- TENDERS TABLE - STANDARDIZED PROPOSAL
-- For project: https://fljvxaqqxlioxljkchte.supabase.co
-- ===============================================

CREATE TABLE tenders (
    -- Primary Key & Timestamps
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Basic Information
    title TEXT NOT NULL,
    summary TEXT,
    context TEXT, -- Keeping your existing field
    
    -- Relationships
    company TEXT, -- Your existing field
    manager_user_id UUID, -- Supabase user who manages this tender
    contact_info TEXT, -- Your existing field
    
    -- Timeline Fields
    due_date TIMESTAMPTZ, -- Your existing field (submission deadline)
    closing_date TIMESTAMPTZ, -- Your existing field
    publication_date TIMESTAMPTZ, -- When tender was published
    
    -- Submission Details
    submission_method TEXT, -- Flexible text for URLs, instructions, and methods
    
    -- Budget Information
    budget_description TEXT,
    budget_estimation DECIMAL(15,2), -- Changed from ? to proper decimal type
    budget_currency TEXT DEFAULT 'EUR',
    
    -- Access & Visibility
    is_public BOOLEAN DEFAULT true, -- Your existing field
    is_active BOOLEAN DEFAULT true, -- Your existing field (renamed from isActive)
    
    -- Processing State (flexible text for app state management)
    process_state TEXT DEFAULT 'pending',
    
    -- Business Status
    status TEXT DEFAULT 'draft' CHECK (status IN (
        'draft', 'review', 'published', 'accepting_submissions', 
        'submission_closed', 'evaluation', 'awarded', 'cancelled', 'archived'
    )),
    
    -- AI Analysis Results
    ai_summary TEXT, -- Generated summary
    
    -- Categorization
    category TEXT, -- IT, Construction, Services, etc.
    tender_type TEXT, -- Open, Restricted, Negotiated, etc.
    
    -- Reference Numbers
    tender_number TEXT UNIQUE, -- Official tender reference
    reference_number TEXT, -- Internal reference
    
    -- Flexible metadata for future extensions
    metadata JSONB DEFAULT '{}'
);

-- ===============================================
-- INDEXES FOR PERFORMANCE
-- ===============================================

-- Essential indexes
CREATE INDEX idx_tenders_status ON tenders(status);
CREATE INDEX idx_tenders_process_state ON tenders(process_state);
CREATE INDEX idx_tenders_company ON tenders(company);
CREATE INDEX idx_tenders_is_active ON tenders(is_active) WHERE is_active = true;
CREATE INDEX idx_tenders_due_date ON tenders(due_date) WHERE due_date IS NOT NULL;
CREATE INDEX idx_tenders_publication_date ON tenders(publication_date);

-- Composite indexes for common queries
CREATE INDEX idx_tenders_status_active ON tenders(status, is_active);
CREATE INDEX idx_tenders_company_status ON tenders(company, status) WHERE company IS NOT NULL;

-- ===============================================
-- TRIGGERS
-- ===============================================

-- Auto-update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_tenders_updated_at 
    BEFORE UPDATE ON tenders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===============================================
-- COMMENTS FOR DOCUMENTATION
-- ===============================================

COMMENT ON TABLE tenders IS 'Main tenders/procurement opportunities table';
COMMENT ON COLUMN tenders.process_state IS 'Flexible application state for document processing and analysis pipeline';
COMMENT ON COLUMN tenders.status IS 'Business lifecycle status of the tender';
