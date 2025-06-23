-- ===============================================
-- TENDERS TABLE - STANDARDIZED & CLEAN ARCHITECTURE
-- For project: https://fljvxaqqxlioxljkchte.supabase.co
-- ===============================================

CREATE TABLE tenders (
    -- Primary Key & Timestamps
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Audit Fields - User Management
    created_by_user_id UUID, -- Supabase user who created this tender
    updated_by_user_id UUID, -- Supabase user who last updated
    
    -- Basic Information
    title TEXT NOT NULL,
    description TEXT,
    context TEXT, -- Keeping existing field for compatibility
    
    -- Organization & Contact
    organization TEXT, -- Issuing organization/company
    contact_person TEXT, -- Main contact person
    contact_email TEXT, -- Contact email address
    
    -- Reference Numbers
    reference_number TEXT, -- Official tender reference number
    tender_number TEXT UNIQUE, -- Internal system reference
    
    -- Timeline Fields (Standardized Names)
    submission_deadline TIMESTAMPTZ, -- When bids must be submitted
    tender_opening_date TIMESTAMPTZ, -- When tender opens for bidding
    publication_date TIMESTAMPTZ, -- When tender was published
    
    -- Budget Information (Standardized Names)
    estimated_value DECIMAL(15,2), -- Estimated project value
    budget_currency TEXT DEFAULT 'EUR',
    budget_description TEXT,
    
    -- Submission Details
    submission_method TEXT, -- Flexible text for URLs, instructions, and methods
    
    -- Access & Visibility
    is_public BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    
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
    
    -- Management Fields
    manager_user_id UUID, -- Supabase user who manages this tender
    company TEXT, -- Company managing this tender
    
    -- Flexible metadata for future extensions
    metadata JSONB DEFAULT '{}'
);

-- ===============================================
-- INDEXES FOR PERFORMANCE
-- ===============================================

-- Essential indexes
CREATE INDEX idx_tenders_status ON tenders(status);
CREATE INDEX idx_tenders_process_state ON tenders(process_state);
CREATE INDEX idx_tenders_organization ON tenders(organization);
CREATE INDEX idx_tenders_is_active ON tenders(is_active) WHERE is_active = true;
CREATE INDEX idx_tenders_submission_deadline ON tenders(submission_deadline) WHERE submission_deadline IS NOT NULL;
CREATE INDEX idx_tenders_publication_date ON tenders(publication_date);

-- User management indexes
CREATE INDEX idx_tenders_created_by ON tenders(created_by_user_id) WHERE created_by_user_id IS NOT NULL;
CREATE INDEX idx_tenders_manager ON tenders(manager_user_id) WHERE manager_user_id IS NOT NULL;

-- Composite indexes for common queries
CREATE INDEX idx_tenders_status_active ON tenders(status, is_active);
CREATE INDEX idx_tenders_organization_status ON tenders(organization, status) WHERE organization IS NOT NULL;

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
-- CONSTRAINTS & VALIDATIONS
-- ===============================================

-- Ensure estimated_value is positive
ALTER TABLE tenders ADD CONSTRAINT chk_estimated_value_positive 
    CHECK (estimated_value IS NULL OR estimated_value > 0);

-- Ensure dates are logical
ALTER TABLE tenders ADD CONSTRAINT chk_submission_after_publication 
    CHECK (submission_deadline IS NULL OR publication_date IS NULL OR submission_deadline >= publication_date);

-- ===============================================
-- COMMENTS FOR DOCUMENTATION
-- ===============================================

COMMENT ON TABLE tenders IS 'Main tenders/procurement opportunities table with standardized field names';
COMMENT ON COLUMN tenders.process_state IS 'Flexible application state for document processing and analysis pipeline';
COMMENT ON COLUMN tenders.status IS 'Business lifecycle status of the tender';
COMMENT ON COLUMN tenders.estimated_value IS 'Estimated project value in specified currency';
COMMENT ON COLUMN tenders.submission_deadline IS 'Final deadline for bid submissions';
COMMENT ON COLUMN tenders.tender_opening_date IS 'Date when tender opens for bidding';
COMMENT ON COLUMN tenders.reference_number IS 'Official tender reference number from issuing organization';
COMMENT ON COLUMN tenders.organization IS 'Name of the organization issuing this tender';
COMMENT ON COLUMN tenders.contact_person IS 'Main contact person for tender inquiries';
COMMENT ON COLUMN tenders.contact_email IS 'Email address for tender-related communications';